use async_trait::async_trait;
use serde::Deserialize;

use crate::domain::errors::DomainResult;

/// CSS selectors for extracting articles from a website's HTML.
#[derive(Debug, Clone, Deserialize)]
pub struct CrawlSelectors {
    pub article_list: String,
    pub title: String,
    pub link: String,
    pub description: Option<String>,
    pub image: Option<String>,
    pub date: Option<String>,
    #[serde(default)]
    pub relative_links: bool,
}

/// A configured site to scrape (used when no RSS feed is available).
#[derive(Debug, Clone, Deserialize)]
pub struct CrawlTarget {
    pub name: String,
    pub url: String,
    pub region: String,
    pub discipline: String,
    pub language: String,
    pub selectors: CrawlSelectors,
}

/// One item extracted from a crawled page.
#[derive(Debug, Clone)]
pub struct ScrapedItem {
    pub title: String,
    pub link: String,
    pub description: Option<String>,
    pub image_url: Option<String>,
    pub published_at: String,
}

/// Scrapes a website using configured CSS selectors.
#[async_trait]
pub trait WebCrawler: Send + Sync {
    async fn crawl(&self, target: &CrawlTarget) -> DomainResult<Vec<ScrapedItem>>;
}
