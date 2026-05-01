//! Application layer — use cases that orchestrate domain ports.

pub mod crawl_sites_use_case;
pub mod ingest_feeds_use_case;
pub mod query_use_cases;
pub mod sync_calendar_use_case;

pub use crawl_sites_use_case::CrawlSitesUseCase;
pub use ingest_feeds_use_case::IngestFeedsUseCase;
pub use query_use_cases::QueryUseCases;
pub use sync_calendar_use_case::SyncCalendarUseCase;
