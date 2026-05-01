//! HTTP RSS/Atom feed fetcher using reqwest + feed-rs.

use std::time::Duration;

use async_trait::async_trait;
use chrono::Utc;

use crate::domain::errors::{DomainError, DomainResult};
use crate::domain::ports::{FeedFetcher, FetchedFeed, FetchedItem};

#[derive(Clone)]
pub struct ReqwestRssFetcher {
    client: reqwest::Client,
}

impl ReqwestRssFetcher {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(15))
            .user_agent("BikeNewsRoom/0.1 (news aggregator)")
            .build()
            .expect("build reqwest client");
        Self { client }
    }
}

impl Default for ReqwestRssFetcher {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl FeedFetcher for ReqwestRssFetcher {
    async fn fetch(&self, url: &str) -> DomainResult<FetchedFeed> {
        let body = self.client.get(url).send().await?.text().await?;

        let parsed = feed_rs::parser::parse(body.as_bytes())
            .map_err(|e| DomainError::FeedParse(e.to_string()))?;

        let mut items = Vec::with_capacity(parsed.entries.len());

        for entry in parsed.entries {
            let title = entry
                .title
                .as_ref()
                .map(|t| t.content.clone())
                .unwrap_or_default();
            if title.is_empty() {
                continue;
            }

            let link = entry
                .links
                .first()
                .map(|l| l.href.clone())
                .or_else(|| entry.id.parse::<url::Url>().ok().map(|u| u.to_string()))
                .unwrap_or_default();
            if link.is_empty() {
                continue;
            }

            let description = entry
                .summary
                .as_ref()
                .map(|s| s.content.clone())
                .or_else(|| entry.content.as_ref().and_then(|c| c.body.clone()));

            let image_url = entry
                .media
                .first()
                .and_then(|m| m.content.first())
                .and_then(|c| c.url.as_ref())
                .map(|u| u.to_string());

            let published_at = entry
                .published
                .or(entry.updated)
                .map(|dt| dt.to_rfc3339())
                .unwrap_or_else(|| Utc::now().to_rfc3339());

            items.push(FetchedItem {
                title,
                link,
                description,
                image_url,
                published_at,
            });
        }

        Ok(FetchedFeed { items })
    }
}
