//! `/sitemap.xml` and `/robots.txt` — SEO scaffolding so search engines
//! actually discover and index every article we've aggregated.
//!
//! Sitemap protocol: <https://www.sitemaps.org/protocol.html>.
//! We emit a single `<urlset>` (cap: 50,000 URLs / 50 MB uncompressed).
//! The home page is included with daily change frequency; each article
//! is `<lastmod>` from its `published_at`. Articles older than 30 days
//! are excluded — search engines de-prioritise stale URLs anyway and we
//! shrink the sitemap to recent-first content.

use axum::{
    extract::State,
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::IntoResponse,
};
use chrono::{Duration, Utc};

use crate::domain::entities::ArticleQuery;
use crate::web::routes::AppState;

const SITEMAP_MAX_AGE_DAYS: i64 = 30;
const SITEMAP_MAX_URLS: i64 = 50_000;

/// Frontend origin (where humans go) — used as the canonical URL host.
fn frontend_origin() -> String {
    std::env::var("FRONTEND_ORIGIN")
        .unwrap_or_else(|_| "https://bike-news-room.pages.dev".to_string())
}

fn esc(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

pub async fn sitemap_xml(State(state): State<AppState>) -> impl IntoResponse {
    let frontend = frontend_origin();
    let cutoff = (Utc::now() - Duration::days(SITEMAP_MAX_AGE_DAYS))
        .format("%Y-%m-%dT%H:%M:%SZ")
        .to_string();

    let q = ArticleQuery {
        page: 1,
        limit: SITEMAP_MAX_URLS,
        since: Some(cutoff),
        ..Default::default()
    };
    let articles = match state.queries.list_articles(&q).await {
        Ok((list, _)) => list,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "internal error").into_response(),
    };

    let mut xml = String::with_capacity(64 * 1024);
    xml.push_str(r#"<?xml version="1.0" encoding="UTF-8"?>"#);
    xml.push('\n');
    xml.push_str(r#"<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">"#);
    xml.push('\n');

    // Home page — change frequency hourly so search engines re-crawl us
    // for fresh news. Priority 1.0 (highest).
    xml.push_str(&format!(
        "  <url>\n    <loc>{}/</loc>\n    <changefreq>hourly</changefreq>\n    <priority>1.0</priority>\n  </url>\n",
        esc(&frontend),
    ));

    // Calendar + Following pages — secondary, weekly change frequency.
    for path in ["/?tab=races", "/?tab=following"] {
        xml.push_str(&format!(
            "  <url>\n    <loc>{}{}</loc>\n    <changefreq>weekly</changefreq>\n    <priority>0.7</priority>\n  </url>\n",
            esc(&frontend),
            esc(path),
        ));
    }

    // One <url> per article. Use the backend's /article/:id URL so
    // crawlers get the OpenGraph stub directly without a 302 hop.
    let backend = std::env::var("BACKEND_ORIGIN").unwrap_or_else(|_| {
        // Fall back to a relative path so the host header is honoured —
        // when the sitemap is fetched from the backend itself, that's
        // the same origin anyway.
        String::new()
    });
    for article in articles {
        let loc = if backend.is_empty() {
            format!("/article/{}", article.id)
        } else {
            format!("{}/article/{}", backend, article.id)
        };
        // Lastmod from published_at. Some feeds emit `YYYY-MM-DD HH:MM:SS`
        // (SQLite default) — both are sitemap-compatible.
        let lastmod = esc(&article.published_at);
        xml.push_str(&format!(
            "  <url>\n    <loc>{}</loc>\n    <lastmod>{}</lastmod>\n    <changefreq>never</changefreq>\n    <priority>0.6</priority>\n  </url>\n",
            esc(&loc),
            lastmod,
        ));
    }

    xml.push_str("</urlset>\n");

    let mut headers = HeaderMap::new();
    headers.insert(
        header::CONTENT_TYPE,
        HeaderValue::from_static("application/xml; charset=utf-8"),
    );
    // Refresh hourly — matches our ingestion cadence.
    headers.insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static("public, max-age=3600"),
    );
    (StatusCode::OK, headers, xml).into_response()
}

pub async fn robots_txt(State(_state): State<AppState>) -> impl IntoResponse {
    // Read-only public site — allow everything, point crawlers at the sitemap
    // so they discover articles efficiently. We block staging/dev paths
    // here as a future-proofing — currently all paths are public anyway.
    let frontend = frontend_origin();
    // Use the backend host the request landed on for the sitemap URL;
    // that way both `bike-news-room.pages.dev/robots.txt` (if we ever add
    // it on Cloudflare) and the backend's `/robots.txt` work.
    let backend = std::env::var("BACKEND_ORIGIN").unwrap_or_default();
    let sitemap_url = if backend.is_empty() {
        // Default to the HF Space host where the backend lives.
        "https://michal-giza-bike-news-room.hf.space/sitemap.xml".to_string()
    } else {
        format!("{backend}/sitemap.xml")
    };

    let body = format!(
        "User-agent: *\n\
         Allow: /\n\
         Disallow: /api/\n\
         \n\
         Sitemap: {sitemap_url}\n\
         \n\
         # Bike News Room — public read-only cycling news aggregator.\n\
         # See {frontend} for the human-facing app.\n",
    );

    let mut headers = HeaderMap::new();
    headers.insert(
        header::CONTENT_TYPE,
        HeaderValue::from_static("text/plain; charset=utf-8"),
    );
    headers.insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static("public, max-age=86400"),
    );
    (StatusCode::OK, headers, body)
}
