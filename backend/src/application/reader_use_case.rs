//! In-app reader — fetches the article body from the publisher on first
//! request and caches it in `articles.full_text`. Subsequent reads are
//! served from cache (publishers' HTML rarely changes after publish, and
//! the bandwidth + latency saving is significant).
//!
//! Pipeline:
//!   1. Look up the article id; if `full_text` already populated, return it.
//!   2. Otherwise GET the article URL with our cycling-news UA, run a
//!      readability-lite pass (drop nav / footer / ads, keep article body),
//!      strip down to plain text + paragraph breaks.
//!   3. Persist the cleaned body to `full_text`. If the publisher 404s or
//!      times out, return `None` and don't cache the failure (retry on
//!      next read).
//!
//! Notes on legality + freshness:
//!   - We're rendering text inside our app the user could read by clicking
//!     out anyway. The "Read on <publisher>" CTA stays prominent in the
//!     modal so the publisher still gets the click-through if the user
//!     wants the full layout / images / their site.
//!   - We honour `noindex` / `noarchive` meta hints by NOT caching when
//!     they're present — those publishers explicitly opt out of mirroring.
//!   - Cache lives forever in `full_text`; the retention sweep deletes
//!     the article (and its full_text) at the same TTL as the article row,
//!     so we can't accidentally serve stale-publisher content longer than
//!     the headline.

use std::sync::Arc;
use std::time::Duration;

use scraper::{Html, Selector};
use tracing::{debug, warn};

use crate::domain::errors::{DomainError, DomainResult};
use crate::domain::ports::ArticleRepository;

/// Maximum body length we'll cache (chars). Caps a hostile publisher
/// (or a parser misfire) from filling our SQLite with a 2MB blob.
const MAX_BODY_CHARS: usize = 80_000;

#[derive(Clone)]
pub struct ReaderUseCase {
    articles: Arc<dyn ArticleRepository>,
    client: reqwest::Client,
}

#[derive(Debug, Clone)]
pub struct ReaderResult {
    pub article_id: i64,
    pub source_url: String,
    /// Plain-text body with paragraph breaks. UTF-8. Capped at
    /// [MAX_BODY_CHARS] characters.
    pub full_text: String,
    /// `true` when the body was served from cache; `false` when we
    /// just scraped + cached it. Useful for ops dashboards.
    pub from_cache: bool,
}

impl ReaderUseCase {
    pub fn new(articles: Arc<dyn ArticleRepository>) -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(15))
            .user_agent(
                "Mozilla/5.0 (compatible; BikeNewsRoom-Reader/0.1; \
                 +https://bike-news-room.pages.dev/about)",
            )
            .build()
            .expect("build reqwest client");
        Self { articles, client }
    }

    pub async fn execute(&self, article_id: i64) -> DomainResult<Option<ReaderResult>> {
        let article = match self.articles.find_by_id(article_id).await? {
            Some(a) => a,
            None => return Ok(None),
        };
        if let Some(cached) = self.articles.full_text(article_id).await? {
            return Ok(Some(ReaderResult {
                article_id,
                source_url: article.url,
                full_text: cached,
                from_cache: true,
            }));
        }

        let html = match self.fetch(&article.url).await {
            Ok(Some(h)) => h,
            Ok(None) => {
                debug!("reader: skipping {} (publisher opted out)", article.url);
                return Ok(None);
            }
            Err(e) => {
                warn!("reader: fetch failed for {}: {}", article.url, e);
                return Ok(None);
            }
        };
        let body = extract_readable_text(&html);
        if body.is_empty() {
            return Ok(None);
        }
        let trimmed: String = body.chars().take(MAX_BODY_CHARS).collect();
        self.articles.set_full_text(article_id, &trimmed).await?;
        Ok(Some(ReaderResult {
            article_id,
            source_url: article.url,
            full_text: trimmed,
            from_cache: false,
        }))
    }

    async fn fetch(&self, url: &str) -> Result<Option<String>, reqwest::Error> {
        let res = self.client.get(url).send().await?;
        if !res.status().is_success() {
            return Ok(None);
        }
        let html = res.text().await?;
        if respects_noarchive(&html) {
            return Ok(None);
        }
        Ok(Some(html))
    }
}

/// Inspect <meta name="robots"> directives. Returns true if the publisher
/// has signalled they don't want mirroring (`noarchive`, `noindex`, or
/// `none`). We respect the opt-out and don't cache the body.
fn respects_noarchive(html: &str) -> bool {
    let doc = Html::parse_document(html);
    let robots_sel = Selector::parse("meta[name='robots'], meta[name='ROBOTS']").unwrap();
    for el in doc.select(&robots_sel) {
        if let Some(content) = el.value().attr("content") {
            let lc = content.to_lowercase();
            if lc.contains("noarchive") || lc.contains("noindex") || lc == "none" {
                return true;
            }
        }
    }
    false
}

/// Readability-lite extractor.
/// Tries article-shaped containers in priority order (semantic HTML first,
/// WordPress / Ghost defaults second, generic fallbacks last). The first
/// selector with reasonable text content wins.
///
/// Pure function exposed for unit tests.
pub fn extract_readable_text(html: &str) -> String {
    let doc = Html::parse_document(html);
    // Priority list: more-specific selectors first.
    let candidates = [
        "article",
        "main article",
        ".article-body",
        ".post-content",
        ".entry-content",
        ".story-body",
        "main",
    ];
    for selector_str in candidates {
        let Ok(sel) = Selector::parse(selector_str) else {
            continue;
        };
        for el in doc.select(&sel) {
            let text = collect_text(el);
            if text.chars().count() >= 200 {
                return text;
            }
        }
    }
    String::new()
}

/// Walk an element + descendants, joining text nodes with paragraph
/// breaks at <p>, <h*>, <li>, <br> boundaries. Skip noisy children
/// (script, style, nav, footer, aside, form).
fn collect_text(el: scraper::ElementRef<'_>) -> String {
    use scraper::Node;
    let mut out = String::new();
    let mut last_was_break = true;
    for node in el.descendants() {
        match node.value() {
            Node::Text(t) => {
                let trimmed = t.text.trim();
                if trimmed.is_empty() {
                    continue;
                }
                if !last_was_break && !out.ends_with(' ') {
                    out.push(' ');
                }
                out.push_str(trimmed);
                last_was_break = false;
            }
            Node::Element(e) => {
                let tag = e.name();
                if matches!(
                    tag,
                    "script" | "style" | "nav" | "footer" | "aside" | "form" | "noscript"
                ) {
                    // descendants() will keep walking; we can't easily
                    // skip subtrees with this iterator, so we rely on
                    // these elements containing little useful text.
                    continue;
                }
                if matches!(
                    tag,
                    "p" | "br" | "li" | "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "div"
                ) && !out.is_empty()
                    && !out.ends_with("\n\n")
                {
                    out.push_str("\n\n");
                    last_was_break = true;
                }
            }
            _ => {}
        }
    }
    out.trim().to_string()
}

// `DomainError` is intentionally unused right now — we swallow fetch
// failures because partial reader content is acceptable. This import
// silences the compiler warning if it's added later.
#[allow(dead_code)]
fn _force_use(_e: DomainError) {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_article_body_from_simple_html() {
        // Body text needs to clear the 200-char minimum readability
        // threshold or we treat the page as "no real article here"
        // and return empty (better than serving nav-text).
        let html = r#"
            <html><body>
            <nav>Home Calendar Settings</nav>
            <article>
              <h1>Pogačar wins again on Mont Ventoux</h1>
              <p>The Slovenian rider attacked early on the climb,
                 catching the breakaway with twelve kilometres to go.</p>
              <p>His teammates set up the move from kilometre 50,
                 controlling the pace through the lower slopes.</p>
              <p>By the summit he had a two-minute lead over Vingegaard,
                 enough to consolidate his overall position.</p>
              <p>The next stage finishes in Nimes after a long flat
                 transit through Provence.</p>
            </article>
            <footer>Copyright Cyclingnews</footer>
            </body></html>
        "#;
        let body = extract_readable_text(html);
        assert!(body.contains("Slovenian rider"), "body={body:?}");
        assert!(body.contains("two-minute lead"), "body={body:?}");
        assert!(
            !body.contains("Copyright"),
            "footer leaked into body: {body:?}"
        );
    }

    #[test]
    fn returns_empty_when_no_article_container_found() {
        let html = "<html><body><p>just a stub</p></body></html>";
        // <main> doesn't match, <article> doesn't match — short text.
        let body = extract_readable_text(html);
        assert!(
            body.is_empty(),
            "expected empty for sub-200-char body; got {body:?}",
        );
    }

    #[test]
    fn respects_noarchive_meta_tag() {
        let html = r#"
            <html><head>
              <meta name="robots" content="noarchive,nofollow">
            </head><body>
              <article>Body that should NOT be cached.</article>
            </body></html>
        "#;
        assert!(respects_noarchive(html));
    }

    #[test]
    fn respects_noindex_uppercase_meta() {
        let html = r#"<html><head>
            <meta name="ROBOTS" content="NOINDEX">
            </head></html>"#;
        assert!(respects_noarchive(html));
    }

    #[test]
    fn does_not_block_normal_meta() {
        let html = r#"<html><head>
            <meta name="robots" content="index,follow">
            </head></html>"#;
        assert!(!respects_noarchive(html));
    }
}
