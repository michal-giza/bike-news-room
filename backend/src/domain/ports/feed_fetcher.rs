use async_trait::async_trait;

use crate::domain::errors::DomainResult;

/// One item parsed from a feed.
#[derive(Debug, Clone)]
pub struct FetchedItem {
    pub title: String,
    pub link: String,
    pub description: Option<String>,
    pub image_url: Option<String>,
    pub published_at: String,
}

/// A successfully fetched + parsed feed.
#[derive(Debug, Clone)]
pub struct FetchedFeed {
    pub items: Vec<FetchedItem>,
}

/// Fetches and parses an RSS/Atom feed.
#[async_trait]
pub trait FeedFetcher: Send + Sync {
    async fn fetch(&self, url: &str) -> DomainResult<FetchedFeed>;
}
