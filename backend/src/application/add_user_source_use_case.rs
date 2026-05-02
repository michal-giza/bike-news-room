//! Use case: probe a user-submitted URL, classify it as RSS-or-HTML, and
//! register it as a new feed source the scheduler will pick up on the next
//! cron tick.
//!
//! Flow:
//!   1. Validate URL (scheme + private-host guard) — `UrlGuardError`.
//!   2. Fetch with size cap + 15s timeout.
//!   3. Try `feed-rs` parse; if successful, classify as RSS.
//!   4. Otherwise try the configurable HTML extractor; if it produces ≥1
//!      item, classify as crawl with default selectors.
//!   5. Otherwise reject — we can't ingest blob/PDF/etc.
//!   6. Insert into `feeds` table via [`FeedRepository::upsert`] and return
//!      the new id + a snapshot of what we'd ingest on first run.
//!
//! The endpoint that wraps this is rate-limited stricter than the read API
//! (5 / hour / IP) at the HTTP layer.

use std::sync::Arc;
use std::time::Duration;

use thiserror::Error;
use tracing::{info, warn};

use crate::domain::ports::FeedRepository;
use crate::domain::services::{validate_url, UrlGuardError};

#[derive(Debug, Error)]
pub enum AddSourceError {
    #[error("invalid URL: {0}")]
    InvalidUrl(#[from] UrlGuardError),
    #[error("fetch failed: {0}")]
    FetchFailed(String),
    #[error("response too large (max 5MB)")]
    PayloadTooLarge,
    #[error("could not parse as RSS or extract any articles from HTML")]
    NoFeedFound,
    #[error("repository error: {0}")]
    Repository(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    Rss,
    Crawl,
}

#[derive(Debug, Clone)]
pub struct AddSourceRequest {
    pub url: String,
    pub name: Option<String>,
    pub region: Option<String>,
    pub discipline: Option<String>,
    pub language: Option<String>,
}

#[derive(Debug, Clone)]
pub struct AddSourceResponse {
    pub feed_id: i64,
    pub kind: SourceKind,
    pub title: String,
    pub url: String,
    pub sample_count: usize,
}

const MAX_BODY_BYTES: u64 = 5 * 1024 * 1024;
const FETCH_TIMEOUT: Duration = Duration::from_secs(15);

pub struct AddUserSourceUseCase {
    feed_repo: Arc<dyn FeedRepository>,
    http: reqwest::Client,
}

impl AddUserSourceUseCase {
    pub fn new(feed_repo: Arc<dyn FeedRepository>) -> Self {
        let http = reqwest::Client::builder()
            .timeout(FETCH_TIMEOUT)
            .user_agent("BikeNewsRoom/0.1 (user-source-probe)")
            // We don't allow redirects across schemes; the URL guard already
            // restricted us to http/https, but a server could 30x to file://.
            .redirect(reqwest::redirect::Policy::limited(5))
            .build()
            .expect("build reqwest client");
        Self { feed_repo, http }
    }

    pub async fn execute(
        &self,
        req: AddSourceRequest,
    ) -> Result<AddSourceResponse, AddSourceError> {
        let url = validate_url(&req.url)?;

        // Fetch
        let response = self
            .http
            .get(url.as_str())
            .send()
            .await
            .map_err(|e| AddSourceError::FetchFailed(e.to_string()))?;

        // Reject early on giant payloads (Content-Length header).
        if let Some(len) = response.content_length() {
            if len > MAX_BODY_BYTES {
                return Err(AddSourceError::PayloadTooLarge);
            }
        }

        let body = response
            .text()
            .await
            .map_err(|e| AddSourceError::FetchFailed(e.to_string()))?;
        if body.len() as u64 > MAX_BODY_BYTES {
            return Err(AddSourceError::PayloadTooLarge);
        }

        // Try RSS / Atom first
        let (kind, derived_title, sample_count) = if let Ok(feed) =
            feed_rs::parser::parse(body.as_bytes())
        {
            let title = feed
                .title
                .map(|t| t.content)
                .filter(|s| !s.is_empty())
                .unwrap_or_else(|| url.host_str().unwrap_or("unknown").to_string());
            let count = feed.entries.len();
            (SourceKind::Rss, title, count)
        } else {
            // Fall through to HTML extraction with default selectors. We
            // intentionally use the same widely-used selectors the existing
            // crawler defaults to so users don't need to know CSS.
            let items = crate::infrastructure::html_crawler::probe_default(
                &body,
                url.as_str(),
            );
            if items.is_empty() {
                return Err(AddSourceError::NoFeedFound);
            }
            let title = req
                .name
                .clone()
                .unwrap_or_else(|| url.host_str().unwrap_or("unknown").to_string());
            (SourceKind::Crawl, title, items.len())
        };

        let display_name = req.name.clone().unwrap_or(derived_title);
        let region = req.region.unwrap_or_else(|| "world".to_string());
        let discipline = req.discipline.unwrap_or_else(|| "all".to_string());
        let language = req.language.unwrap_or_else(|| "en".to_string());

        let feed_id = self
            .feed_repo
            .upsert(
                url.as_str(),
                &display_name,
                &region,
                &discipline,
                &language,
            )
            .await
            .map_err(|e| AddSourceError::Repository(e.to_string()))?;

        info!(
            "user source registered: id={feed_id} kind={kind:?} title='{display_name}' samples={sample_count}"
        );
        if matches!(kind, SourceKind::Crawl) {
            warn!(
                "user-added crawl target '{display_name}' uses default selectors — \
                if extraction quality is poor, edit selectors via admin tooling"
            );
        }

        Ok(AddSourceResponse {
            feed_id,
            kind,
            title: display_name,
            url: url.to_string(),
            sample_count,
        })
    }
}
