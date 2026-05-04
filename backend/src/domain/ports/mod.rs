//! Ports — trait abstractions for I/O. Implementations live in `infrastructure/`.

pub mod article_repository;
pub mod feed_fetcher;
pub mod feed_repository;
pub mod race_link_repository;
pub mod race_repository;
pub mod source_candidate_repository;
pub mod subscriber_repository;
pub mod web_crawler;

pub use article_repository::ArticleRepository;
pub use feed_fetcher::{FeedFetcher, FetchedFeed, FetchedItem};
pub use feed_repository::FeedRepository;
pub use race_link_repository::RaceLinkRepository;
pub use race_repository::RaceRepository;
pub use source_candidate_repository::SourceCandidateRepository;
pub use subscriber_repository::SubscriberRepository;
pub use web_crawler::{CrawlSelectors, CrawlTarget, ScrapedItem, WebCrawler};
