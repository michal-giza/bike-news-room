//! Domain entities — pure data types with no persistence concerns.

use serde::Serialize;

/// A persisted news article.
///
/// `cluster_count` is a view-only field populated by list/find queries —
/// number of duplicate-articles pointing at this article as canonical.
/// Defaults to 0 when the SQL doesn't include the column (e.g. inserts).
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Article {
    pub id: i64,
    pub feed_id: i64,
    pub title: String,
    pub description: Option<String>,
    pub url: String,
    pub image_url: Option<String>,
    pub published_at: String,
    pub fetched_at: Option<String>,
    pub title_hash: String,
    pub category: Option<String>,
    pub region: Option<String>,
    pub discipline: Option<String>,
    pub language: Option<String>,
    pub is_duplicate: i32,
    pub canonical_id: Option<i64>,
    #[sqlx(default)]
    pub cluster_count: i64,
}

/// An article candidate that hasn't been persisted yet.
/// Use cases construct these and hand them to a repository.
#[derive(Debug, Clone)]
pub struct ArticleDraft {
    pub feed_id: i64,
    pub title: String,
    pub description: Option<String>,
    pub url: String,
    pub image_url: Option<String>,
    pub published_at: String,
    pub title_hash: String,
    pub category: Option<String>,
    pub region: String,
    pub discipline: String,
    pub language: String,
}

/// A registered news source (RSS feed or crawl target).
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Feed {
    pub id: i64,
    pub url: String,
    pub title: String,
    pub region: String,
    pub discipline: Option<String>,
    pub language: Option<String>,
    pub last_fetched_at: Option<String>,
    pub error_count: i32,
    pub active: i32,
}

/// Per-category counts for the categories endpoint.
#[derive(Debug, Clone, Serialize)]
pub struct CategoryCount {
    pub category: String,
    pub count: i64,
}

/// A scheduled race (ProCyclingStats season calendar).
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Race {
    pub id: i64,
    pub name: String,
    pub start_date: String, // ISO-8601 yyyy-mm-dd
    pub end_date: Option<String>,
    pub country: Option<String>,
    pub category: Option<String>, // e.g. "2.UWT", "1.Pro"
    pub discipline: String,        // road / mtb / gravel / cx / track
    pub url: Option<String>,
    pub fetched_at: Option<String>,
}

/// Draft (pre-persistence) race.
#[derive(Debug, Clone)]
pub struct RaceDraft {
    pub name: String,
    pub start_date: String,
    pub end_date: Option<String>,
    pub country: Option<String>,
    pub category: Option<String>,
    pub discipline: String,
    pub url: Option<String>,
}

/// Health status of a feed for the circuit breaker.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FeedHealth {
    Healthy,
    Degraded,
    /// Feed has failed enough times that we should skip it.
    Disabled,
}

impl FeedHealth {
    pub const DEGRADED_THRESHOLD: i32 = 3;
    pub const DISABLED_THRESHOLD: i32 = 10;

    pub fn from_error_count(count: i32) -> Self {
        if count >= Self::DISABLED_THRESHOLD {
            Self::Disabled
        } else if count >= Self::DEGRADED_THRESHOLD {
            Self::Degraded
        } else {
            Self::Healthy
        }
    }

    pub fn should_skip(self) -> bool {
        matches!(self, Self::Disabled)
    }
}

/// Query parameters for listing articles.
#[derive(Debug, Clone, Default)]
pub struct ArticleQuery {
    pub page: i64,
    pub limit: i64,
    pub region: Option<String>,
    pub discipline: Option<String>,
    pub category: Option<String>,
    pub search: Option<String>,
    pub since: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn feed_health_classifies_by_error_count() {
        assert_eq!(FeedHealth::from_error_count(0), FeedHealth::Healthy);
        assert_eq!(FeedHealth::from_error_count(2), FeedHealth::Healthy);
        assert_eq!(FeedHealth::from_error_count(3), FeedHealth::Degraded);
        assert_eq!(FeedHealth::from_error_count(9), FeedHealth::Degraded);
        assert_eq!(FeedHealth::from_error_count(10), FeedHealth::Disabled);
        assert_eq!(FeedHealth::from_error_count(100), FeedHealth::Disabled);
    }

    #[test]
    fn only_disabled_should_be_skipped() {
        assert!(!FeedHealth::Healthy.should_skip());
        assert!(!FeedHealth::Degraded.should_skip());
        assert!(FeedHealth::Disabled.should_skip());
    }
}
