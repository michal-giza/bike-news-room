use async_trait::async_trait;

use crate::domain::entities::{Race, RaceDraft};
use crate::domain::errors::DomainResult;

/// Method names are namespaced with `_race` so they don't collide with
/// `ArticleRepository` / `FeedRepository` when the same struct implements
/// all three traits — calls then resolve unambiguously without UFCS.
#[async_trait]
pub trait RaceRepository: Send + Sync {
    /// Insert or update on (name + start_date). Returns the row's id.
    async fn upsert_race(&self, draft: &RaceDraft) -> DomainResult<i64>;

    /// Upcoming races, optionally filtered by discipline. Past races excluded.
    async fn upcoming_races(
        &self,
        discipline: Option<&str>,
        limit: i64,
    ) -> DomainResult<Vec<Race>>;

    async fn count_races(&self) -> DomainResult<i64>;
}
