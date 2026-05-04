//! Use case: fetch race calendars and persist via [`RaceRepository`].
//!
//! Pure orchestration — talks to the scraper through `fetch_fn` (so tests can
//! swap in a fake) and a `RaceRepository`. Logs how many races were upserted
//! per source and skips sources that fail without aborting the rest.

use std::sync::Arc;

use tracing::{info, warn};

use crate::domain::entities::RaceDraft;
use crate::domain::errors::DomainResult;
use crate::domain::ports::RaceRepository;
use crate::infrastructure::race_calendar_scraper::{
    default_sources, fetch_calendar, CalendarSource,
};

pub struct SyncCalendarUseCase {
    race_repo: Arc<dyn RaceRepository>,
}

impl SyncCalendarUseCase {
    pub fn new(race_repo: Arc<dyn RaceRepository>) -> Self {
        Self { race_repo }
    }

    /// Execute against the default ProCyclingStats sources.
    pub async fn execute(&self) -> usize {
        self.execute_with_sources(&default_sources()).await
    }

    /// Used in tests — execute with caller-provided sources + fetcher.
    pub async fn execute_with_sources(&self, sources: &[CalendarSource]) -> usize {
        let mut total = 0;
        for source in sources {
            match fetch_calendar(source).await {
                Ok(drafts) => {
                    let n = self.persist_all(&drafts).await;
                    info!(
                        "calendar sync ({}): persisted {} of {} races",
                        source.discipline,
                        n,
                        drafts.len()
                    );
                    total += n;
                }
                Err(e) => warn!("calendar sync ({}): fetch failed — {e}", source.discipline),
            }
        }
        total
    }

    async fn persist_all(&self, drafts: &[RaceDraft]) -> usize {
        let mut ok = 0;
        for draft in drafts {
            if self.upsert(draft).await.is_ok() {
                ok += 1;
            }
        }
        ok
    }

    async fn upsert(&self, draft: &RaceDraft) -> DomainResult<i64> {
        self.race_repo.upsert_race(draft).await
    }
}
