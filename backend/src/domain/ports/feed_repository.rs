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

    /// Record the outcome of a fetch's article-yield count. When the
    /// fetch produced ≥1 new article, resets the empty-streak counter
    /// and stamps `last_nonempty_at`. When zero, increments the streak
    /// counter so the staleness reporter can flag long-quiet sources.
    async fn record_fetch_yield(&self, feed_id: i64, new_count: usize) -> DomainResult<()>;

    /// Mark a feed as dead — it served HTTP 200 but its body contained
    /// a known shutdown banner phrase. Stores the matched phrase in
    /// `dead_reason` for ops review, sets `active=0` so the scheduler
    /// stops fetching it on the next pass.
    async fn mark_dead(&self, feed_id: i64, reason: &str) -> DomainResult<()>;

    /// Feeds that look stale: alive (no errors), but the empty-streak
    /// counter exceeds `min_empty_streak`. Surfaced by the admin
    /// endpoint so an operator can review + retire.
    async fn list_stale(&self, min_empty_streak: i32) -> DomainResult<Vec<Feed>>;

    /// Feeds explicitly marked dead by the shutdown detector. Same
    /// shape as list_stale, separate query so the admin UI can colour
    /// them differently.
    async fn list_dead(&self) -> DomainResult<Vec<Feed>>;
}
