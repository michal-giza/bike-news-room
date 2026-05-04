//! Auto-poster for X/Twitter.
//!
//! Hourly cron job: pick the highest-quality articles that have landed
//! since we last posted, tweet each one with title + share URL, record
//! the article_id in `tweeted_articles` so we don't double-post.
//!
//! Authentication: X v2's `POST /2/tweets` endpoint requires a user-context
//! OAuth 2.0 bearer token. We read it from `TWITTER_OAUTH2_TOKEN`. Tokens
//! expire after 2h; the operator is responsible for refreshing via the
//! developer portal (or wiring a cron-based refresher later — out of scope
//! for the MVP).
//!
//! When `TWITTER_OAUTH2_TOKEN` is unset, the use case is a no-op. That
//! keeps local dev runs from accidentally tweeting and lets us deploy the
//! cron scaffolding without enabling posting.

use std::sync::Arc;

use serde_json::json;
use sqlx::SqlitePool;
use tracing::{info, warn};

use crate::domain::entities::{Article, ArticleQuery};
use crate::domain::ports::ArticleRepository;

const MAX_PER_RUN: usize = 3;
const TWEET_LIMIT: usize = 280;
/// X auto-shortens any URL to 23 chars regardless of original length.
/// We reserve 23 + 1 (space) when computing how much title we can fit.
const URL_BUDGET: usize = 24;

pub struct AutoTweetUseCase {
    articles: Arc<dyn ArticleRepository>,
    pool: SqlitePool,
    oauth2_token: Option<String>,
    /// Public-facing share URL prefix — points at the backend's /article/:id
    /// landing page so X's crawler gets OpenGraph cards.
    article_url_base: String,
}

impl AutoTweetUseCase {
    pub fn new(articles: Arc<dyn ArticleRepository>, pool: SqlitePool) -> Self {
        let oauth2_token = std::env::var("TWITTER_OAUTH2_TOKEN")
            .ok()
            .filter(|s| !s.is_empty());
        let article_url_base = std::env::var("BACKEND_ORIGIN")
            .unwrap_or_else(|_| "https://michal-giza-bike-news-room.hf.space".to_string());
        Self {
            articles,
            pool,
            oauth2_token,
            article_url_base,
        }
    }

    pub async fn execute(&self) -> usize {
        let Some(token) = self.oauth2_token.clone() else {
            info!("auto-tweet: TWITTER_OAUTH2_TOKEN not set, skipping run");
            return 0;
        };

        // Pull a generous window of recent articles, then filter by
        // tweeted_articles in Rust. SQLite NOT IN over a small set is fine.
        let q = ArticleQuery {
            page: 1,
            limit: 50,
            ..Default::default()
        };
        let (recent, _) = match self.articles.query(&q).await {
            Ok(r) => r,
            Err(e) => {
                warn!("auto-tweet: list articles failed: {e}");
                return 0;
            }
        };

        let mut to_tweet: Vec<Article> = Vec::new();
        for a in recent {
            if to_tweet.len() >= MAX_PER_RUN {
                break;
            }
            // Skip duplicates and already-tweeted articles.
            if a.is_duplicate != 0 {
                continue;
            }
            match self.already_tweeted(a.id).await {
                Ok(true) => continue,
                Ok(false) => {}
                Err(e) => {
                    warn!("auto-tweet: dedup lookup failed: {e}");
                    continue;
                }
            }
            to_tweet.push(a);
        }

        if to_tweet.is_empty() {
            info!("auto-tweet: nothing new to post");
            return 0;
        }

        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(15))
            .build()
            .expect("reqwest");

        let mut posted = 0usize;
        for a in &to_tweet {
            let body = format_tweet(&a.title, &self.share_url(a.id));
            match self.post_tweet(&client, &token, &body).await {
                Ok(tweet_id) => {
                    posted += 1;
                    if let Err(e) = self.record_tweet(a.id, tweet_id.as_deref()).await {
                        warn!("auto-tweet: record failed for article {}: {e}", a.id);
                    }
                }
                Err(e) => warn!("auto-tweet: post failed for article {}: {e}", a.id),
            }
        }
        info!("auto-tweet: posted {posted}/{} tweets", to_tweet.len());
        posted
    }

    fn share_url(&self, article_id: i64) -> String {
        format!(
            "{}/article/{}",
            self.article_url_base.trim_end_matches('/'),
            article_id
        )
    }

    async fn already_tweeted(&self, article_id: i64) -> Result<bool, sqlx::Error> {
        let n: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM tweeted_articles WHERE article_id = ?")
                .bind(article_id)
                .fetch_one(&self.pool)
                .await?;
        Ok(n > 0)
    }

    async fn record_tweet(
        &self,
        article_id: i64,
        tweet_id: Option<&str>,
    ) -> Result<(), sqlx::Error> {
        sqlx::query("INSERT OR IGNORE INTO tweeted_articles (article_id, tweet_id) VALUES (?, ?)")
            .bind(article_id)
            .bind(tweet_id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn post_tweet(
        &self,
        client: &reqwest::Client,
        token: &str,
        text: &str,
    ) -> Result<Option<String>, String> {
        let resp = client
            .post("https://api.twitter.com/2/tweets")
            .bearer_auth(token)
            .json(&json!({ "text": text }))
            .send()
            .await
            .map_err(|e| format!("send: {e}"))?;
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        if !status.is_success() {
            return Err(format!("X returned {status}: {body}"));
        }
        // Response shape: { "data": { "id": "...", "text": "..." } }
        let parsed: serde_json::Value =
            serde_json::from_str(&body).map_err(|e| format!("parse response: {e}"))?;
        let tweet_id = parsed
            .get("data")
            .and_then(|d| d.get("id"))
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());
        Ok(tweet_id)
    }
}

/// Format a tweet so it fits in the 280-char limit. If the title is too
/// long for the remaining budget after the URL, truncate it on a word
/// boundary and add an ellipsis.
fn format_tweet(title: &str, url: &str) -> String {
    let title_budget = TWEET_LIMIT.saturating_sub(URL_BUDGET);
    let title = if title.chars().count() <= title_budget {
        title.to_string()
    } else {
        let mut shortened: String = title.chars().take(title_budget - 1).collect();
        // Trim back to the last space so we don't cut a word in half.
        if let Some(last_space) = shortened.rfind(' ') {
            if last_space > title_budget / 2 {
                shortened.truncate(last_space);
            }
        }
        format!("{shortened}…")
    };
    format!("{title} {url}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn short_title_fits_verbatim() {
        let out = format_tweet("Pogačar wins again", "https://x.test/article/1");
        assert_eq!(out, "Pogačar wins again https://x.test/article/1");
    }

    #[test]
    fn long_title_gets_truncated_at_word_boundary() {
        let title = "Pogačar wins again ".repeat(40);
        let out = format_tweet(&title, "https://x.test/article/1");
        // We don't actually count tweets correctly without X's URL shortener,
        // but the produced length should be roughly within TWEET_LIMIT.
        assert!(out.chars().count() <= TWEET_LIMIT);
        assert!(out.contains("…"));
        assert!(out.ends_with("https://x.test/article/1"));
    }
}
