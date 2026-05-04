//! Server-side HTML for `/article/:id`.
//!
//! Flutter Web is a SPA — it can't emit per-article `<meta og:*>` tags at
//! build time. So when a crawler (Twitterbot, Slackbot, Facebookbot,
//! Discordbot, …) requests `/article/123`, we sniff the User-Agent and
//! return a tiny self-describing HTML page with OpenGraph + Twitter Card
//! meta. Real browsers get a 302 to the SPA at
//! `https://<frontend-origin>/?article=123` — same destination, fewer wasted
//! bytes for humans, and the crawlers get the rich preview they need.

use axum::{
    extract::{Path, State},
    http::{header, HeaderMap, StatusCode},
    response::{Html, IntoResponse, Redirect, Response},
};

use crate::domain::entities::Article;
use crate::web::routes::AppState;

/// Frontend origin. Read from `FRONTEND_ORIGIN` env so the same binary can
/// target staging or prod without recompiling.
fn frontend_origin() -> String {
    std::env::var("FRONTEND_ORIGIN")
        .unwrap_or_else(|_| "https://bike-news-room.pages.dev".to_string())
}

/// Crawlers / link-preview bots we want to serve OpenGraph HTML to.
/// Match is case-insensitive substring.
const CRAWLER_UA_HINTS: &[&str] = &[
    "twitterbot",
    "facebookexternalhit",
    "slackbot",
    "discordbot",
    "linkedinbot",
    "telegrambot",
    "whatsapp",
    "skypeuripreview",
    "redditbot",
    "googlebot",
    "bingbot",
    "duckduckbot",
    "applebot",
    "pinterest",
    "bsky",
];

fn is_crawler(headers: &HeaderMap) -> bool {
    headers
        .get(header::USER_AGENT)
        .and_then(|v| v.to_str().ok())
        .map(|ua| {
            let lower = ua.to_lowercase();
            CRAWLER_UA_HINTS.iter().any(|hint| lower.contains(hint))
        })
        .unwrap_or(false)
}

/// HTML-escape user-supplied strings before interpolating into a template.
fn esc(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

/// Truncate description for OpenGraph (FB/Slack render up to ~200 chars).
fn truncate(s: &str, max: usize) -> String {
    if s.chars().count() <= max {
        return s.to_string();
    }
    let truncated: String = s.chars().take(max - 1).collect();
    format!("{truncated}…")
}

fn render(article: &Article) -> String {
    let frontend = frontend_origin();
    let title = esc(&article.title);
    let description = esc(&truncate(article.description.as_deref().unwrap_or(""), 220));
    let canonical = format!("{frontend}/?article={}", article.id);
    let original = esc(&article.url);
    let image = article
        .image_url
        .as_deref()
        .map(esc)
        .unwrap_or_else(|| format!("{frontend}/icons/Icon-512.png"));
    let published = esc(&article.published_at);
    let section = esc(article.discipline.as_deref().unwrap_or("cycling"));

    format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>{title} — Bike News Room</title>
<meta name="description" content="{description}">

<!-- OpenGraph -->
<meta property="og:type" content="article">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{description}">
<meta property="og:url" content="{canonical}">
<meta property="og:image" content="{image}">
<meta property="og:site_name" content="Bike News Room">
<meta property="article:published_time" content="{published}">
<meta property="article:section" content="{section}">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{description}">
<meta name="twitter:image" content="{image}">

<!-- schema.org NewsArticle — what Google News + Discover key off -->
<script type="application/ld+json">
{{
  "@context": "https://schema.org",
  "@type": "NewsArticle",
  "headline": "{title}",
  "description": "{description}",
  "image": "{image}",
  "datePublished": "{published}",
  "url": "{canonical}",
  "mainEntityOfPage": "{canonical}",
  "publisher": {{
    "@type": "Organization",
    "name": "Bike News Room",
    "url": "{frontend}"
  }}
}}
</script>

<meta http-equiv="refresh" content="0;url={canonical}">
<link rel="canonical" href="{canonical}">
</head>
<body>
<h1>{title}</h1>
<p>{description}</p>
<p><a href="{original}">Read the original on the publisher's site</a></p>
<p><a href="{canonical}">Open in Bike News Room</a></p>
</body>
</html>
"#,
    )
}

/// `GET /article/:id`
///
/// Crawlers get the OpenGraph stub HTML. Real browsers get a 302 to the
/// SPA's `/?article=<id>` — same destination, fewer wasted bytes.
pub async fn article_landing(
    State(state): State<AppState>,
    Path(id): Path<i64>,
    headers: HeaderMap,
) -> Response {
    let frontend = frontend_origin();

    if !is_crawler(&headers) {
        return Redirect::to(&format!("{frontend}/?article={id}")).into_response();
    }

    match state.queries.find_article(id).await {
        Ok(Some(article)) => {
            let html = render(&article);
            (StatusCode::OK, Html(html)).into_response()
        }
        Ok(None) => (
            StatusCode::NOT_FOUND,
            Html(format!(
                "<!DOCTYPE html><html><head><meta http-equiv=\"refresh\" \
                 content=\"0;url={frontend}/\"><title>Not found</title></head></html>"
            )),
        )
            .into_response(),
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "internal error").into_response(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;

    #[test]
    fn detects_known_crawler_user_agents() {
        let cases = [
            "Twitterbot/1.0",
            "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
            "facebookexternalhit/1.1",
            "Slackbot 1.0 (+https://api.slack.com/robots)",
            "Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)",
            "WhatsApp/2.21",
            "Mozilla/5.0 LinkedInBot/1.0",
        ];
        for ua in cases {
            let mut h = HeaderMap::new();
            h.insert(header::USER_AGENT, HeaderValue::from_str(ua).unwrap());
            assert!(is_crawler(&h), "should detect crawler: {ua}");
        }
    }

    #[test]
    fn ignores_real_browsers() {
        let cases = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 \
             (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            "curl/8.4.0",
        ];
        for ua in cases {
            let mut h = HeaderMap::new();
            h.insert(header::USER_AGENT, HeaderValue::from_str(ua).unwrap());
            assert!(!is_crawler(&h), "should not detect crawler: {ua}");
        }
    }

    #[test]
    fn html_escapes_user_input() {
        assert_eq!(
            esc("<script>alert(1)</script>"),
            "&lt;script&gt;alert(1)&lt;/script&gt;"
        );
        assert_eq!(
            esc("a \"b\" 'c' & d"),
            "a &quot;b&quot; &#39;c&#39; &amp; d"
        );
    }

    #[test]
    fn truncate_respects_unicode_chars() {
        assert_eq!(truncate("hello", 10), "hello");
        assert_eq!(truncate("hello world", 5), "hell…");
        assert_eq!(truncate("Pogačar wins", 5).chars().count(), 5);
    }
}
