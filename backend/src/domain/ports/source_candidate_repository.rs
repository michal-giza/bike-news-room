//! Persistence port for the auto-growing source-candidate pipeline.

use async_trait::async_trait;

use crate::domain::entities::SourceCandidate;
use crate::domain::errors::DomainResult;

#[async_trait]
pub trait SourceCandidateRepository: Send + Sync {
    /// Record one mention of `domain`. Inserts a new row on first sighting,
    /// otherwise increments `mention_count` and refreshes `last_seen_at`.
    /// `sample_url` is the full URL we extracted the domain from — kept as
    /// a probe target if/when the candidate is promoted.
    async fn record_mention(&self, domain: &str, sample_url: &str) -> DomainResult<()>;

    /// List candidates with `status = 'pending'`, sorted by mention_count desc.
    /// Used by the admin endpoint.
    async fn list_pending(
        &self,
        min_mentions: i64,
        limit: i64,
    ) -> DomainResult<Vec<SourceCandidate>>;

    async fn find(&self, id: i64) -> DomainResult<Option<SourceCandidate>>;

    /// Mark a candidate `approved` and link it to the new feed.
    async fn mark_approved(&self, id: i64, feed_id: i64) -> DomainResult<()>;

    async fn mark_rejected(&self, id: i64) -> DomainResult<()>;

    /// Whether this domain is already known to us — either as an existing feed
    /// or already an approved/rejected candidate. Used to short-circuit mining
    /// so we don't bump counts for domains we've already adjudicated.
    async fn domain_already_known(&self, domain: &str) -> DomainResult<bool>;
}
