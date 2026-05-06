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
    /// `true` (default): future races only — preserves the existing
    /// calendar-page contract. `false`: past races, newest-first. Drives
    /// the per-race "past editions" view.
    pub upcoming: Option<bool>,
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
    /// ISO-8601 (or SQLite-style) cutoff. Only returns articles older
    /// than this. Powers the per-race "past edition" archive view.
    pub before: Option<String>,
    /// Race slug from the matcher catalogue. When set, joins the
    /// `race_articles` link table so only articles tagged for that race
    /// are returned.
    pub race_slug: Option<String>,
    /// Comma-separated discipline list. The bg-poller subscribes to N
    /// disciplines and needs to fetch them in one call (cap on iOS is
    /// "a few" requests per OS-decided fire). Single `discipline=` still
    /// works for backwards compat; if both are set `disciplines` wins.
    pub disciplines: Option<String>,
    /// Comma-separated region list. Same rationale as `disciplines`.
    pub regions: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AddSourceBody {
    pub url: String,
    /// Optional human-readable name. Falls back to the feed's own title or
    /// the URL's hostname when absent.
    pub name: Option<String>,
    pub region: Option<String>,
    pub discipline: Option<String>,
    pub language: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AddSourceResponseDto {
    pub feed_id: i64,
    /// "rss" or "crawl"
    pub kind: String,
    pub title: String,
    pub url: String,
    pub sample_count: usize,
}
