//! Read-side use cases for the HTTP API.

use std::sync::Arc;

use crate::domain::entities::{Article, ArticleQuery, CategoryCount, Feed, Race};
use crate::domain::errors::DomainResult;
use crate::domain::ports::{ArticleRepository, FeedRepository, RaceRepository};

#[derive(Clone)]
pub struct QueryUseCases {
    article_repo: Arc<dyn ArticleRepository>,
    feed_repo: Arc<dyn FeedRepository>,
    race_repo: Arc<dyn RaceRepository>,
}

impl QueryUseCases {
    pub fn new(
        article_repo: Arc<dyn ArticleRepository>,
        feed_repo: Arc<dyn FeedRepository>,
        race_repo: Arc<dyn RaceRepository>,
    ) -> Self {
        Self {
            article_repo,
            feed_repo,
            race_repo,
        }
    }

    pub async fn upcoming_races(
        &self,
        discipline: Option<&str>,
        limit: i64,
    ) -> DomainResult<Vec<Race>> {
        self.race_repo.upcoming_races(discipline, limit).await
    }

    pub async fn past_races(
        &self,
        discipline: Option<&str>,
        limit: i64,
    ) -> DomainResult<Vec<Race>> {
        self.race_repo.past_races(discipline, limit).await
    }

    pub async fn list_articles(&self, q: &ArticleQuery) -> DomainResult<(Vec<Article>, i64)> {
        self.article_repo.query(q).await
    }

    pub async fn find_article(&self, id: i64) -> DomainResult<Option<Article>> {
        self.article_repo.find_by_id(id).await
    }

    pub async fn cluster_for(&self, canonical_id: i64) -> DomainResult<Vec<Article>> {
        self.article_repo.cluster_for(canonical_id).await
    }

    pub async fn list_feeds(&self) -> DomainResult<Vec<Feed>> {
        self.feed_repo.list_all().await
    }

    /// Feeds whose empty-streak crossed the staleness threshold —
    /// alive (HTTP 200, no errors) but consistently producing nothing.
    /// Default threshold of 30 ≈ 15 days at our 30-min ingest cadence.
    pub async fn list_stale_feeds(&self, min_empty_streak: i32) -> DomainResult<Vec<Feed>> {
        self.feed_repo.list_stale(min_empty_streak).await
    }

    /// Feeds the shutdown-banner detector flagged dead. Same shape as
    /// stale; admin UI usually distinguishes them by colour or column.
    pub async fn list_dead_feeds(&self) -> DomainResult<Vec<Feed>> {
        self.feed_repo.list_dead().await
    }

    pub async fn category_counts(&self) -> DomainResult<Vec<CategoryCount>> {
        self.article_repo.category_counts().await
    }

    pub async fn article_count(&self) -> DomainResult<i64> {
        self.article_repo.count().await
    }

    pub async fn last_fetch(&self) -> DomainResult<Option<String>> {
        self.feed_repo.last_fetch_time().await
    }
}
