//! Persistence port for daily-digest subscribers.

use async_trait::async_trait;

use crate::domain::entities::Subscriber;
use crate::domain::errors::DomainResult;

#[async_trait]
pub trait SubscriberRepository: Send + Sync {
    /// Insert a new pending subscriber. If `email` already exists in any
    /// state, returns the existing row instead of erroring — that lets the
    /// signup endpoint be idempotent (and re-sends a confirmation email
    /// when the user clicks "subscribe" twice).
    async fn upsert_pending(
        &self,
        email: &str,
        confirm_token: &str,
        unsubscribe_token: &str,
    ) -> DomainResult<Subscriber>;

    async fn find_by_confirm_token(&self, token: &str) -> DomainResult<Option<Subscriber>>;

    async fn find_by_unsubscribe_token(&self, token: &str) -> DomainResult<Option<Subscriber>>;

    async fn mark_confirmed(&self, id: i64) -> DomainResult<()>;

    async fn mark_unsubscribed(&self, id: i64) -> DomainResult<()>;

    /// Active subscribers — recipients of the daily digest.
    async fn list_active(&self) -> DomainResult<Vec<Subscriber>>;
}
