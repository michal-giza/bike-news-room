//! Application layer — use cases that orchestrate domain ports.

pub mod add_user_source_use_case;
pub mod auto_tweet_use_case;
pub mod backfill_archive_use_case;
pub mod crawl_sites_use_case;
pub mod digest_use_case;
pub mod ingest_feeds_use_case;
pub mod mine_candidates_use_case;
pub mod query_use_cases;
pub mod race_matcher_use_case;
pub mod reader_use_case;
pub mod retention_use_case;
pub mod sync_calendar_use_case;
pub mod trending_use_case;
pub mod wiki_context_use_case;

pub use add_user_source_use_case::{
    AddSourceError, AddSourceRequest, AddSourceResponse, AddUserSourceUseCase, SourceKind,
};
pub use auto_tweet_use_case::AutoTweetUseCase;
pub use backfill_archive_use_case::{BackfillArchiveUseCase, BackfillReport};
pub use crawl_sites_use_case::CrawlSitesUseCase;
pub use digest_use_case::DigestUseCase;
pub use ingest_feeds_use_case::IngestFeedsUseCase;
pub use mine_candidates_use_case::MineCandidatesUseCase;
pub use query_use_cases::QueryUseCases;
pub use race_matcher_use_case::RaceMatcherUseCase;
pub use reader_use_case::{ReaderResult, ReaderUseCase};
pub use retention_use_case::{RetentionReport, RetentionUseCase};
pub use sync_calendar_use_case::SyncCalendarUseCase;
pub use trending_use_case::{TrendingTerm, TrendingUseCase};
pub use wiki_context_use_case::{WikiContext, WikiContextUseCase};
