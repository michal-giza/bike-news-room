//! HTTP request/response DTOs.

use serde::{Deserialize, Serialize};

use crate::domain::entities::{Article, CategoryCount, Feed, Race};

#[derive(Debug, Serialize)]
pub struct ArticlesResponse {
    pub articles: Vec<Article>,
    pub total: i64,
    pub page: i64,
    pub has_more: bool,
}

#[derive(Debug, Serialize)]
pub struct FeedsResponse {
    pub feeds: Vec<Feed>,
}

#[derive(Debug, Serialize)]
pub struct CategoriesResponse {
    pub categories: Vec<CategoryCount>,
}

#[derive(Debug, Serialize)]
pub struct HealthResponse {
    pub status: String,
    pub article_count: i64,
    pub last_fetch: Option<String>,
    pub uptime_seconds: u64,
}

#[derive(Debug, Serialize)]
pub struct MetricsResponse {
    pub article_count: i64,
    pub feed_count: usize,
    pub healthy_feeds: usize,
    pub degraded_feeds: usize,
    pub disabled_feeds: usize,
    pub last_fetch: Option<String>,
    pub uptime_seconds: u64,
    pub categories: Vec<CategoryCount>,
    pub feed_health: Vec<FeedHealthEntry>,
}

#[derive(Debug, Serialize)]
pub struct FeedHealthEntry {
    pub id: i64,
    pub title: String,
    pub url: String,
    pub region: String,
    pub error_count: i32,
    pub last_fetched_at: Option<String>,
    /// "healthy" | "degraded" | "disabled"
    pub status: &'static str,
}

#[derive(Debug, Serialize)]
pub struct RacesResponse {
    pub races: Vec<Race>,
}

#[derive(Debug, Deserialize)]
pub struct RacesQueryParams {
    pub discipline: Option<String>,
    pub limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct ArticleQueryParams {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub region: Option<String>,
    pub discipline: Option<String>,
    pub category: Option<String>,
    pub search: Option<String>,
    pub since: Option<String>,
}
