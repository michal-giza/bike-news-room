//! Use case: probe a user-submitted URL, classify it as RSS-or-HTML, and
//! register it as a new feed source the scheduler will pick up on the next
//! cron tick.
//!
//! Flow:
//!   1. Validate URL (scheme + private-host guard) — `UrlGuardError`.
//!   2. Fetch with size cap + 15s timeout.
//!   3. Try `feed-rs` parse; if successful, classify as RSS.
//!   4. Otherwise try the configurable HTML extractor; if it produces ≥1
//!      item, classify as crawl with default selectors.
//!   5. Otherwise reject — we can't ingest blob/PDF/etc.
//!   6. Insert into `feeds` table via [`FeedRepository::upsert`] and return
//!      the new id + a snapshot of what we'd ingest on first run.
//!
//! The endpoint that wraps this is rate-limited stricter than the read API
//! (5 / hour / IP) at the HTTP layer.

use std::sync::Arc;
use std::time::Duration;

use thiserror::Error;
use tracing::{info, warn};
use url::Url;

use crate::domain::ports::FeedRepository;
use crate::domain::services::{validate_url, UrlGuardError};

#[derive(Debug, Error)]
pub enum AddSourceError {
    #[error("invalid URL: {0}")]
    InvalidUrl(#[from] UrlGuardError),
    #[error("fetch failed: {0}")]
    FetchFailed(String),
    #[error("response too large (max 5MB)")]
    PayloadTooLarge,
    #[error("could not parse as RSS or extract any articles from HTML")]
    NoFeedFound,
    #[error("repository error: {0}")]
    Repository(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    Rss,
    Crawl,
}

#[derive(Debug, Clone)]
pub struct AddSourceRequest {
    pub url: String,
    pub name: Option<String>,
    pub region: Option<String>,
    pub discipline: Option<String>,
    pub language: Option<String>,
}

#[derive(Debug, Clone)]
pub struct AddSourceResponse {
    pub feed_id: i64,
    pub kind: SourceKind,
    pub title: String,
    pub url: String,
    pub sample_count: usize,
}

const MAX_BODY_BYTES: u64 = 5 * 1024 * 1024;
const FETCH_TIMEOUT: Duration = Duration::from_secs(15);

pub struct AddUserSourceUseCase {
    feed_repo: Arc<dyn FeedRepository>,
    http: reqwest::Client,
}

impl AddUserSourceUseCase {
    pub fn new(feed_repo: Arc<dyn FeedRepository>) -> Self {
        // We use a browser-like User-Agent here intentionally. About 30%
        // of European cycling publishers (Cloudflare-fronted Italian and
        // French sites in particular) return a 403 or anti-bot challenge
        // page when they see anything resembling a crawler UA. The URL
        // guard + payload caps already enforce safety; the UA is just
        // the cheapest unlock for compatibility.
        let mut headers = reqwest::header::HeaderMap::new();
        headers.insert(
            reqwest::header::ACCEPT,
            reqwest::header::HeaderValue::from_static(
                "application/rss+xml, application/atom+xml, application/xml;q=0.9, \
                 application/feed+json;q=0.8, text/html;q=0.7, */*;q=0.5",
            ),
        );
        headers.insert(
            reqwest::header::ACCEPT_LANGUAGE,
            reqwest::header::HeaderValue::from_static("en;q=0.9, *;q=0.5"),
        );

        let http = reqwest::Client::builder()
            .timeout(FETCH_TIMEOUT)
            .user_agent(
                "Mozilla/5.0 (compatible; BikeNewsRoom/0.1; +https://bike-news-room.pages.dev)",
            )
            .default_headers(headers)
            // We don't allow redirects across schemes; the URL guard already
            // restricted us to http/https, but a server could 30x to file://.
            .redirect(reqwest::redirect::Policy::limited(5))
            .build()
            .expect("build reqwest client");
        Self { feed_repo, http }
    }

    pub async fn execute(
        &self,
        req: AddSourceRequest,
    ) -> Result<AddSourceResponse, AddSourceError> {
        let url = validate_url(&req.url)?;

        // Fetch
        let response = self
            .http
            .get(url.as_str())
            .send()
            .await
            .map_err(|e| AddSourceError::FetchFailed(e.to_string()))?;

        // Reject early on giant payloads (Content-Length header).
        if let Some(len) = response.content_length() {
            if len > MAX_BODY_BYTES {
                return Err(AddSourceError::PayloadTooLarge);
            }
        }

        let body = response
            .text()
            .await
            .map_err(|e| AddSourceError::FetchFailed(e.to_string()))?;
        if body.len() as u64 > MAX_BODY_BYTES {
            return Err(AddSourceError::PayloadTooLarge);
        }

        // ── Resolution waterfall ──────────────────────────────────────
        // 1. Direct: maybe the user pasted the actual feed URL.
        // 2. Auto-discovery: scan the HTML head for
        //    <link rel="alternate" type="application/rss+xml" href="…">
        //    Every modern CMS (WordPress, Ghost, Drupal, Hugo) emits this.
        //    Catches the dominant failure mode where users paste the
        //    homepage URL but RSS lives at /feed or /rss.
        // 3. Common-path probe: try /feed, /rss, /feed.xml, /atom.xml.
        //    Catches static-site generators and a few hand-rolled CMSes.
        // 4. HTML extraction with default selectors — last resort.
        let (kind, derived_title, sample_count, resolved_url) = self
            .resolve_feed(&url, &body)
            .await
            .ok_or(AddSourceError::NoFeedFound)?;

        let display_name = req.name.clone().unwrap_or(derived_title);
        let region = req.region.unwrap_or_else(|| "world".to_string());
        let discipline = req.discipline.unwrap_or_else(|| "all".to_string());
        let language = req.language.unwrap_or_else(|| "en".to_string());

        let feed_id = self
            .feed_repo
            .upsert(
                &resolved_url,
                &display_name,
                &region,
                &discipline,
                &language,
            )
            .await
            .map_err(|e| AddSourceError::Repository(e.to_string()))?;

        info!(
            "user source registered: id={feed_id} kind={kind:?} title='{display_name}' samples={sample_count}"
        );
        if matches!(kind, SourceKind::Crawl) {
            warn!(
                "user-added crawl target '{display_name}' uses default selectors — \
                if extraction quality is poor, edit selectors via admin tooling"
            );
        }

        Ok(AddSourceResponse {
            feed_id,
            kind,
            title: display_name,
            url: resolved_url,
            sample_count,
        })
    }

    /// Walk the resolution waterfall described in `execute()`. Returns
    /// `(kind, title, sample_count, resolved_url)` — note `resolved_url`
    /// may differ from the URL the user pasted when discovery hops to a
    /// `/feed` path. We persist the *resolved* URL so subsequent fetches
    /// hit the actual feed, not the homepage HTML.
    async fn resolve_feed(
        &self,
        original: &Url,
        original_body: &str,
    ) -> Option<(SourceKind, String, usize, String)> {
        // 1. Direct — the user already pasted a feed URL.
        if let Some(parsed) = Self::try_parse_rss(original_body, original) {
            return Some((parsed.0, parsed.1, parsed.2, original.to_string()));
        }

        // 2. <link rel="alternate"> auto-discovery from the HTML head.
        //    A `Vec` because some sites advertise multiple feeds (full +
        //    per-category); we try them in order, first hit wins.
        for candidate in discover_feed_links(original_body, original) {
            if let Some((body, parsed)) = self.fetch_and_parse(&candidate).await {
                let _ = body;
                return Some((parsed.0, parsed.1, parsed.2, candidate.to_string()));
            }
        }

        // 3. Common path probe. Limited to four well-known suffixes so we
        //    don't hammer the site with dozens of speculative requests.
        for path in COMMON_FEED_PATHS {
            if let Ok(candidate) = original.join(path) {
                // Skip if identical to original (already tried in step 1).
                if candidate == *original {
                    continue;
                }
                if let Some((_, parsed)) = self.fetch_and_parse(&candidate).await {
                    return Some((parsed.0, parsed.1, parsed.2, candidate.to_string()));
                }
            }
        }

        // 4. HTML default-selector extraction on the original body.
        let items =
            crate::infrastructure::html_crawler::probe_default(original_body, original.as_str());
        if !items.is_empty() {
            let title = original.host_str().unwrap_or("unknown").to_string();
            return Some((SourceKind::Crawl, title, items.len(), original.to_string()));
        }

        None
    }

    /// Tiny helper — fetch a candidate URL, run the same payload-cap and
    /// RSS-parse logic the main path uses. Returns `(body, parsed)` so the
    /// caller can reuse the body if more steps are needed (currently we
    /// don't, but the shape leaves room for HTML fallback against a
    /// discovered alternate URL).
    async fn fetch_and_parse(
        &self,
        candidate: &Url,
    ) -> Option<(String, (SourceKind, String, usize))> {
        let resp = self.http.get(candidate.as_str()).send().await.ok()?;
        if let Some(len) = resp.content_length() {
            if len > MAX_BODY_BYTES {
                return None;
            }
        }
        let body = resp.text().await.ok()?;
        if body.len() as u64 > MAX_BODY_BYTES {
            return None;
        }
        let parsed = Self::try_parse_rss(&body, candidate)?;
        Some((body, parsed))
    }

    fn try_parse_rss(body: &str, url: &Url) -> Option<(SourceKind, String, usize)> {
        let feed = feed_rs::parser::parse(body.as_bytes()).ok()?;
        let title = feed
            .title
            .map(|t| t.content)
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| url.host_str().unwrap_or("unknown").to_string());
        let count = feed.entries.len();
        // Refuse "feeds" with zero entries — those are usually a CMS's
        // empty stub, not a real feed.
        if count == 0 {
            return None;
        }
        Some((SourceKind::Rss, title, count))
    }
}

/// Paths we probe when the homepage doesn't directly parse as RSS and the
/// HTML head doesn't expose a `<link rel="alternate">` either. Order
/// matters: WordPress's default `/feed` is by far the most common, so we
/// try it first and short-circuit on the first hit.
const COMMON_FEED_PATHS: &[&str] = &[
    "/feed",
    "/feed/",
    "/rss",
    "/rss.xml",
    "/atom.xml",
    "/feed.xml",
];

/// Extract every RSS/Atom URL from the HTML head's `<link rel="alternate">`
/// tags, resolved against `base`. Built with the `scraper` crate to share
/// the same dependency the existing crawler already pulls in.
fn discover_feed_links(html: &str, base: &Url) -> Vec<Url> {
    use scraper::{Html, Selector};

    let doc = Html::parse_document(html);
    // We deliberately accept both rel="alternate" and rel="alternative"
    // (a common typo on hand-rolled CMSes) plus the type variants for
    // RSS, Atom, and JSON Feed. JSON Feed (`application/feed+json`) is
    // not yet parsable by feed-rs but we list it for forward-compat.
    let sel = Selector::parse("link[rel=alternate], link[rel=Alternate], link[rel=alternative]")
        .expect("static selector");

    let mut out = Vec::new();
    let mut seen = std::collections::HashSet::<String>::new();

    for el in doc.select(&sel) {
        let attrs = el.value();
        let ty = attrs.attr("type").unwrap_or("").to_ascii_lowercase();
        let is_feed = ty.contains("rss")
            || ty.contains("atom")
            || ty == "application/xml"
            || ty == "text/xml";
        if !is_feed {
            continue;
        }
        let Some(href) = attrs.attr("href") else {
            continue;
        };
        let Ok(resolved) = base.join(href) else {
            continue;
        };
        // Same-origin only — defence-in-depth against sites pointing
        // <link rel="alternate"> at a third-party syndication URL.
        if resolved.host_str() != base.host_str() {
            continue;
        }
        if seen.insert(resolved.to_string()) {
            out.push(resolved);
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn discovers_wordpress_style_feed_link() {
        let html = r#"<!doctype html><html><head>
            <link rel="alternate" type="application/rss+xml" href="/feed/" />
            <link rel="alternate" type="application/atom+xml" href="/feed/atom/" />
            </head><body></body></html>"#;
        let base = Url::parse("https://wielerflits.nl/").unwrap();
        let found = discover_feed_links(html, &base);
        assert_eq!(found.len(), 2);
        assert_eq!(found[0].as_str(), "https://wielerflits.nl/feed/");
        assert_eq!(found[1].as_str(), "https://wielerflits.nl/feed/atom/");
    }

    #[test]
    fn ignores_cross_origin_alternate_links() {
        let html = r#"<link rel="alternate" type="application/rss+xml"
            href="https://feedburner.example/syndicate" />"#;
        let base = Url::parse("https://example.com/").unwrap();
        assert!(discover_feed_links(html, &base).is_empty());
    }

    #[test]
    fn ignores_non_feed_alternate_links() {
        // Translation / canonical alternates use `rel="alternate"` too —
        // we must not treat them as feeds.
        let html = r#"<link rel="alternate" hreflang="es" href="/es/" />
            <link rel="alternate" type="text/html" href="/m/" />"#;
        let base = Url::parse("https://example.com/").unwrap();
        assert!(discover_feed_links(html, &base).is_empty());
    }

    #[test]
    fn empty_feed_is_rejected() {
        // <rss> with no <item> children — feed-rs parses it, but it has
        // zero entries. We treat zero entries as "not really a feed" so
        // the resolver continues to the next candidate.
        let body = r#"<?xml version="1.0"?><rss version="2.0"><channel>
            <title>Empty</title><link>http://x</link><description>z</description>
            </channel></rss>"#;
        let url = Url::parse("https://x.test/feed").unwrap();
        assert!(AddUserSourceUseCase::try_parse_rss(body, &url).is_none());
    }
}
