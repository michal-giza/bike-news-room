//! Outbound-link mining for auto-growing the source list.
//!
//! When a new article lands, its description often links to other cycling
//! sites we haven't ingested yet. By extracting those domains and counting
//! how many times each gets cited across articles, we surface promising
//! candidates for an admin to review.
//!
//! No promotion is automatic — the admin still approves/rejects via
//! `/api/admin/source-candidates/:id/promote|reject`. That keeps the source
//! list curated while the long tail of niche cycling sites comes from data,
//! not manual feed-hunting.

use std::collections::HashSet;
use std::sync::Arc;

use scraper::{Html, Selector};
use tracing::warn;
use url::Url;

use crate::domain::ports::SourceCandidateRepository;
use crate::domain::services::validate_url;

pub struct MineCandidatesUseCase {
    repo: Arc<dyn SourceCandidateRepository>,
}

impl MineCandidatesUseCase {
    pub fn new(repo: Arc<dyn SourceCandidateRepository>) -> Self {
        Self { repo }
    }

    /// Extract outbound domains from an article's HTML description and record
    /// each unique domain as one mention. We dedupe within the same article so
    /// a single post linking to `cyclingnews.com` 5 times only counts once.
    pub async fn mine_article(&self, description_html: Option<&str>, article_url: &str) {
        let Some(html) = description_html else {
            return;
        };
        let candidates = extract_outbound_domains(html, article_url);
        for (domain, sample_url) in candidates {
            // Skip domains we already track or have already adjudicated.
            match self.repo.domain_already_known(&domain).await {
                Ok(true) => continue,
                Ok(false) => {}
                Err(e) => {
                    warn!("source_candidates lookup failed for {domain}: {e}");
                    continue;
                }
            }
            if let Err(e) = self.repo.record_mention(&domain, &sample_url).await {
                warn!("source_candidates mention failed for {domain}: {e}");
            }
        }
    }
}

/// Pull every `<a href>` out of `html`, resolve relative URLs against
/// `base_url`, drop ones that point back to the article's own domain or
/// fail SSRF safety checks, and return one (domain, sample_url) pair per
/// unique domain. The sample_url is the full original URL — used as the
/// probe target if the candidate is later promoted.
fn extract_outbound_domains(html: &str, base_url: &str) -> Vec<(String, String)> {
    let doc = Html::parse_fragment(html);
    let sel = Selector::parse("a[href]").expect("static selector");

    let base_domain = Url::parse(base_url)
        .ok()
        .and_then(|u| u.host_str().map(normalize_domain));

    let mut seen = HashSet::<String>::new();
    let mut out = Vec::new();

    for el in doc.select(&sel) {
        let Some(href) = el.value().attr("href") else {
            continue;
        };
        let resolved = resolve_url(base_url, href);
        let Some(url) = resolved else { continue };
        if validate_url(url.as_str()).is_err() {
            continue;
        }
        let Some(host) = url.host_str() else { continue };
        let domain = normalize_domain(host);

        // Skip self-links and known low-signal generic hosts.
        if base_domain.as_deref() == Some(&domain) {
            continue;
        }
        if is_uninteresting_domain(&domain) {
            continue;
        }
        if !seen.insert(domain.clone()) {
            continue;
        }
        out.push((domain, url.to_string()));
    }
    out
}

fn resolve_url(base: &str, href: &str) -> Option<Url> {
    if let Ok(u) = Url::parse(href) {
        return Some(u);
    }
    let base = Url::parse(base).ok()?;
    base.join(href).ok()
}

/// Strip a leading `www.` so `www.cyclingnews.com` and `cyclingnews.com`
/// merge into one candidate row.
fn normalize_domain(host: &str) -> String {
    host.trim_start_matches("www.").to_ascii_lowercase()
}

/// Hosts we'd never promote to a feed — social platforms, tracking pixels,
/// CDN buckets, the major search engines. Skipping them up front keeps the
/// candidates list legible.
fn is_uninteresting_domain(domain: &str) -> bool {
    const NOISE: &[&str] = &[
        "twitter.com",
        "x.com",
        "facebook.com",
        "instagram.com",
        "youtube.com",
        "youtu.be",
        "tiktok.com",
        "linkedin.com",
        "reddit.com",
        "pinterest.com",
        "amazon.com",
        "amazon.co.uk",
        "amzn.to",
        "google.com",
        "googletagmanager.com",
        "googleadservices.com",
        "doubleclick.net",
        "bit.ly",
        "t.co",
        "buff.ly",
        "feedburner.com",
        "feeds.feedburner.com",
        "wikipedia.org",
        "strava.com",
        "github.com",
        "apple.com",
        "spotify.com",
    ];
    NOISE
        .iter()
        .any(|n| domain == *n || domain.ends_with(&format!(".{n}")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_unique_external_domains() {
        let html = r#"
            <p>See more on <a href="https://cyclingnews.com/foo">CN</a>
            and <a href="https://www.cyclingnews.com/bar">CN again</a>
            and <a href="https://velowire.com/">VW</a>.</p>
        "#;
        let out = extract_outbound_domains(html, "https://example.com/article/1");
        let domains: Vec<_> = out.iter().map(|(d, _)| d.as_str()).collect();
        assert!(domains.contains(&"cyclingnews.com"));
        assert!(domains.contains(&"velowire.com"));
        assert_eq!(domains.len(), 2, "www.* and bare merged");
    }

    #[test]
    fn skips_self_links() {
        let html = r#"<a href="/other">self</a><a href="https://example.com/x">also self</a>"#;
        let out = extract_outbound_domains(html, "https://example.com/article/1");
        assert!(out.is_empty(), "no outbound = no candidates");
    }

    #[test]
    fn drops_social_noise() {
        let html = r#"
            <a href="https://twitter.com/foo">tw</a>
            <a href="https://m.facebook.com/x">fb</a>
            <a href="https://niceblog.cc/post">real</a>
        "#;
        let out = extract_outbound_domains(html, "https://example.com/article/1");
        assert_eq!(out.len(), 1);
        assert_eq!(out[0].0, "niceblog.cc");
    }

    #[test]
    fn rejects_unsafe_urls() {
        let html = r#"<a href="javascript:alert(1)">x</a>
            <a href="http://192.168.1.1/x">private</a>"#;
        let out = extract_outbound_domains(html, "https://example.com/article/1");
        assert!(out.is_empty());
    }

    #[test]
    fn resolves_relative_urls() {
        // A relative href has no host of its own, so it should not produce a
        // candidate (resolving it gives the base origin, which is the
        // article's own domain and therefore self-link skipped).
        let html = r#"<a href="/foo">rel</a>"#;
        let out = extract_outbound_domains(html, "https://example.com/article/1");
        assert!(out.is_empty());
    }
}
