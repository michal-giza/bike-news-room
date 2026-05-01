use async_trait::async_trait;

use crate::domain::entities::Feed;
use crate::domain::errors::DomainResult;

/// Persistence port for registered feeds.
#[async_trait]
pub trait FeedRepository: Send + Sync {
    /// Insert or update a feed by URL. Returns the feed's ID.
    async fn upsert(
        &self,
        url: &str,
        title: &str,
        region: &str,
        discipline: &str,
        language: &str,
    ) -> DomainResult<i64>;

    /// Mark a successful fetch (resets error count, updates timestamp).
    async fn mark_fetched(&self, feed_id: i64) -> DomainResult<()>;

    /// Increment error counter (used by circuit breaker).
    async fn increment_error(&self, feed_id: i64) -> DomainResult<()>;

    async fn list_all(&self) -> DomainResult<Vec<Feed>>;

    /// Look up a single feed by id — used by the circuit breaker so we don't
    /// pay an O(N) scan of all feeds for every source on every ingest.
    async fn find_feed(&self, id: i64) -> DomainResult<Option<Feed>>;

    async fn last_fetch_time(&self) -> DomainResult<Option<String>>;
}
