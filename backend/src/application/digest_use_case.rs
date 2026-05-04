//! Daily-digest email pipeline.
//!
//! Builds a "today's top stories" email body and pushes it to every active
//! subscriber via Resend's HTTP API. Resend is chosen over SMTP because:
//! 1. Free tier covers our expected volume (3,000 emails/mo) for $0
//! 2. HTTP API works through HF Spaces' restricted egress; SMTP often doesn't
//! 3. They handle deliverability (DKIM/SPF) for us
//!
//! Pipeline: scheduled at 07:00 UTC → fetch last 24h articles → render
//! HTML+text → POST one email per subscriber. Failures per recipient are
//! logged but do not abort the run.

use std::sync::Arc;

use chrono::{Duration, Utc};
use serde_json::json;
use tracing::{info, warn};

use crate::domain::entities::{Article, ArticleQuery, Subscriber};
use crate::domain::ports::{ArticleRepository, SubscriberRepository};

const TOP_N_ARTICLES: i64 = 12;
const DEFAULT_FROM: &str = "Bike News Room <digest@bike-news-room.pages.dev>";

pub struct DigestUseCase {
    articles: Arc<dyn ArticleRepository>,
    subscribers: Arc<dyn SubscriberRepository>,
    /// Public-facing URL for the unsubscribe link. We point at the backend
    /// so the URL is stable even if the SPA host changes.
    public_base_url: String,
    /// Resend API key. When `None`, sending is skipped — useful for local
    /// runs and tests so we don't accidentally email real people.
    resend_api_key: Option<String>,
    from_address: String,
}

impl DigestUseCase {
    pub fn new(
        articles: Arc<dyn ArticleRepository>,
        subscribers: Arc<dyn SubscriberRepository>,
    ) -> Self {
        let resend_api_key = std::env::var("RESEND_API_KEY")
            .ok()
            .filter(|s| !s.is_empty());
        let public_base_url = std::env::var("BACKEND_ORIGIN")
            .unwrap_or_else(|_| "https://michal-giza-bike-news-room.hf.space".to_string());
        let from_address =
            std::env::var("DIGEST_FROM").unwrap_or_else(|_| DEFAULT_FROM.to_string());
        Self {
            articles,
            subscribers,
            public_base_url,
            resend_api_key,
            from_address,
        }
    }

    /// Run a single digest cycle. Returns the number of emails successfully
    /// dispatched. Safe to call repeatedly; each call sends one digest per
    /// active subscriber.
    pub async fn execute(&self) -> usize {
        let Some(api_key) = self.resend_api_key.clone() else {
            info!("digest: RESEND_API_KEY not set, skipping send");
            return 0;
        };

        let yesterday = (Utc::now() - Duration::hours(24))
            .format("%Y-%m-%dT%H:%M:%S")
            .to_string();
        let q = ArticleQuery {
            page: 1,
            limit: TOP_N_ARTICLES,
            since: Some(yesterday),
            ..Default::default()
        };
        let (top, _) = match self.articles.query(&q).await {
            Ok(t) => t,
            Err(e) => {
                warn!("digest: failed to fetch top articles: {e}");
                return 0;
            }
        };
        if top.is_empty() {
            info!("digest: no articles in the last 24h, skipping send");
            return 0;
        }

        let recipients = match self.subscribers.list_active().await {
            Ok(r) => r,
            Err(e) => {
                warn!("digest: failed to load subscribers: {e}");
                return 0;
            }
        };
        if recipients.is_empty() {
            info!("digest: no active subscribers, skipping send");
            return 0;
        }

        info!(
            "digest: sending {} articles to {} subscribers",
            top.len(),
            recipients.len()
        );

        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(15))
            .build()
            .expect("reqwest client");

        let mut sent = 0usize;
        for sub in &recipients {
            match self.send_one(&client, &api_key, sub, &top).await {
                Ok(_) => sent += 1,
                Err(e) => warn!("digest: send to {} failed: {e}", sub.email),
            }
        }
        info!("digest: sent {sent}/{} emails", recipients.len());
        sent
    }

    async fn send_one(
        &self,
        client: &reqwest::Client,
        api_key: &str,
        sub: &Subscriber,
        articles: &[Article],
    ) -> Result<(), String> {
        // Tokens are URL-safe (hex from sha256), so we don't need to encode.
        let unsub_url = format!(
            "{}/api/subscribers/unsubscribe?token={}",
            self.public_base_url.trim_end_matches('/'),
            sub.unsubscribe_token,
        );

        let html = render_html(articles, &unsub_url, &self.public_base_url);
        let text = render_text(articles, &unsub_url);

        let today = Utc::now().format("%a %d %b").to_string();
        let payload = json!({
            "from": self.from_address,
            "to": [sub.email],
            "subject": format!("Bike News Room — {today}"),
            "html": html,
            "text": text,
            // RFC 8058 one-click-unsubscribe headers — keeps Gmail/Yahoo
            // happy and means "Mark spam" gets routed to a real handler.
            "headers": [
                {"name": "List-Unsubscribe", "value": format!("<{unsub_url}>")},
                {"name": "List-Unsubscribe-Post", "value": "List-Unsubscribe=One-Click"},
            ],
        });

        let resp = client
            .post("https://api.resend.com/emails")
            .bearer_auth(api_key)
            .json(&payload)
            .send()
            .await
            .map_err(|e| format!("resend POST: {e}"))?;
        if !resp.status().is_success() {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_default();
            return Err(format!("resend {status}: {body}"));
        }
        Ok(())
    }
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

fn render_html(articles: &[Article], unsub_url: &str, base_url: &str) -> String {
    let mut s = String::with_capacity(8 * 1024);
    s.push_str(
        "<!doctype html><html><body style=\"font-family:Georgia,serif;\
         max-width:600px;margin:0 auto;padding:24px;color:#1a1a1a\">",
    );
    s.push_str(
        "<h1 style=\"font-size:28px;letter-spacing:-0.02em;margin:0 0 4px\">Bike News Room</h1>",
    );
    s.push_str(
        "<p style=\"font-family:'JetBrains Mono',monospace;font-size:11px;\
         letter-spacing:0.12em;text-transform:uppercase;color:#888;margin:0 0 24px\">\
         Today's wire</p>",
    );

    for a in articles {
        let title = esc(&a.title);
        let link = format!("{}/article/{}", base_url.trim_end_matches('/'), a.id);
        let desc = a
            .description
            .as_deref()
            .map(|d| {
                let stripped: String = strip_tags(d);
                let trimmed = stripped.trim();
                if trimmed.len() > 200 {
                    format!("{}…", &trimmed[..200])
                } else {
                    trimmed.to_string()
                }
            })
            .unwrap_or_default();

        s.push_str(&format!(
            "<div style=\"margin:0 0 24px;padding-bottom:18px;border-bottom:1px solid #eee\">\
             <a href=\"{link}\" style=\"color:#1a1a1a;text-decoration:none\">\
             <h2 style=\"font-size:20px;line-height:1.3;margin:0 0 6px\">{title}</h2></a>\
             <p style=\"font-size:14px;line-height:1.5;color:#444;margin:0\">{desc}</p>\
             </div>",
        ));
    }

    s.push_str(&format!(
        "<p style=\"font-size:12px;color:#888;margin-top:32px;text-align:center\">\
         You're receiving this because you signed up at bike-news-room.\
         <br><a href=\"{}\" style=\"color:#888\">Unsubscribe</a></p>",
        esc(unsub_url),
    ));
    s.push_str("</body></html>");
    s
}

fn render_text(articles: &[Article], unsub_url: &str) -> String {
    let mut s = String::with_capacity(2048);
    s.push_str("BIKE NEWS ROOM — TODAY'S WIRE\n\n");
    for (i, a) in articles.iter().enumerate() {
        s.push_str(&format!("{}. {}\n", i + 1, a.title));
        s.push_str(&format!("   {}\n\n", a.url));
    }
    s.push_str(&format!("\nUnsubscribe: {unsub_url}\n"));
    s
}

/// Crude HTML-tag stripper — adequate for digest previews because we already
/// store description text that's been sanitized at ingest time. We only run
/// it as a defence-in-depth in case raw HTML slipped through.
fn strip_tags(html: &str) -> String {
    let mut out = String::with_capacity(html.len());
    let mut in_tag = false;
    for c in html.chars() {
        match c {
            '<' => in_tag = true,
            '>' => in_tag = false,
            _ if !in_tag => out.push(c),
            _ => {}
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn esc_escapes_html_specials() {
        assert_eq!(esc("a&b<c>\""), "a&amp;b&lt;c&gt;&quot;");
    }

    #[test]
    fn strip_tags_removes_markup() {
        assert_eq!(strip_tags("<p>hi <b>there</b></p>"), "hi there");
    }

    #[test]
    fn render_text_lists_articles_with_urls() {
        let a = Article {
            id: 1,
            feed_id: 1,
            title: "Pogačar wins".into(),
            description: None,
            url: "https://example.com/x".into(),
            image_url: None,
            published_at: "2026-05-01".into(),
            fetched_at: None,
            title_hash: "h".into(),
            category: None,
            region: None,
            discipline: None,
            language: None,
            is_duplicate: 0,
            canonical_id: None,
            cluster_count: 0,
        };
        let out = render_text(&[a], "https://x.test/u?t=abc");
        assert!(out.contains("Pogačar wins"));
        assert!(out.contains("https://example.com/x"));
        assert!(out.contains("https://x.test/u?t=abc"));
    }
}
