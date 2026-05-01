//! Ports — trait abstractions for I/O. Implementations live in `infrastructure/`.

pub mod article_repository;
pub mod feed_fetcher;
pub mod feed_repository;
pub mod race_repository;
pub mod web_crawler;

pub use article_repository::ArticleRepository;
pub use feed_fetcher::{FeedFetcher, FetchedFeed, FetchedItem};
pub use feed_repository::FeedRepository;
pub use race_repository::RaceRepository;
pub use web_crawler::{CrawlSelectors, CrawlTarget, ScrapedItem, WebCrawler};
