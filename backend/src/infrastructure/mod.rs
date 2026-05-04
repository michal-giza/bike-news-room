//! Infrastructure layer — concrete adapters that implement domain ports.

pub mod archive_backfill_targets;
pub mod config;
pub mod html_crawler;
pub mod race_calendar_scraper;
pub mod rss_fetcher;
pub mod snapshot;
pub mod sqlite_repository;

pub use config::{AppConfig, FeedSource};
pub use html_crawler::ScraperHtmlCrawler;
pub use rss_fetcher::ReqwestRssFetcher;
pub use snapshot::{spawn_periodic_snapshot, SnapshotConfig};
pub use sqlite_repository::{init_schema, SqliteRepository};
