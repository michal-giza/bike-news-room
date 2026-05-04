//! Persistence port for the matcher-driven race-article link table.
//!
//! Two responsibilities:
//!   1. Maintain the `tracked_races` brand catalogue (Tour de France,
//!      Giro, Rampage, etc. — year-agnostic).
//!   2. Record `race_articles` links produced by the matcher at ingest
//!      time, and surface them at query time so a user following a race
//!      can see every article we've ever linked to it.

use async_trait::async_trait;

use crate::domain::errors::DomainResult;

#[async_trait]
pub trait RaceLinkRepository: Send + Sync {
    /// Idempotent insert. Returns the `tracked_races.id`. Used at startup
    /// when seeding the catalogue from the JSON file — re-runs are no-ops.
    async fn upsert_tracked_race(
        &self,
        slug: &str,
        display_name: &str,
        discipline: &str,
    ) -> DomainResult<i64>;

    /// Record a match. Idempotent (PRIMARY KEY (tracked_race_id, article_id)).
    /// `matched_alias` is stored for debugging / audit ("why is this
    /// article tagged Tour de France?").
    async fn link_article(
        &self,
        tracked_race_id: i64,
        article_id: i64,
        matched_alias: &str,
    ) -> DomainResult<()>;

    /// All articles linked to a given race slug, newest first. Used by
    /// the per-race archive view in the Following tab.
    async fn list_articles_for_race(
        &self,
        race_slug: &str,
        limit: i64,
        before: Option<&str>,
    ) -> DomainResult<Vec<i64>>;

    /// Fast count for the race-detail header ("Tour de France · 1,247 articles").
    async fn count_articles_for_race(&self, race_slug: &str) -> DomainResult<i64>;
}
