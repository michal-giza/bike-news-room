use async_trait::async_trait;

use crate::domain::entities::{Article, ArticleDraft, ArticleQuery, CategoryCount};
use crate::domain::errors::DomainResult;

/// Persistence port for articles.
#[async_trait]
pub trait ArticleRepository: Send + Sync {
    /// Insert a new article. Returns the new ID, or `None` if it already existed
    /// (deduplicated on URL or hash by the implementation).
    async fn insert(&self, draft: &ArticleDraft) -> DomainResult<Option<i64>>;

    /// Has any article with this URL been stored?
    async fn url_exists(&self, url: &str) -> DomainResult<bool>;

    /// Has any article with this title hash been stored?
    async fn hash_exists(&self, hash: &str) -> DomainResult<bool>;

    /// Mark `article_id` as a duplicate of `canonical_id`.
    async fn mark_duplicate(&self, article_id: i64, canonical_id: i64) -> DomainResult<()>;

    /// Recently published, non-duplicate articles for fuzzy matching.
    /// `since` is an ISO-8601 timestamp lower bound.
    async fn recent_titles(&self, since: &str) -> DomainResult<Vec<(i64, String)>>;

    /// Paginated query.
    async fn query(&self, q: &ArticleQuery) -> DomainResult<(Vec<Article>, i64)>;

    async fn find_by_id(&self, id: i64) -> DomainResult<Option<Article>>;

    async fn count(&self) -> DomainResult<i64>;

    async fn category_counts(&self) -> DomainResult<Vec<CategoryCount>>;

    /// All duplicate articles that point to `canonical_id`. Used to build
    /// the "+N sources covering this" indicator on cards.
    async fn cluster_for(&self, canonical_id: i64) -> DomainResult<Vec<Article>>;

    /// Pull every non-duplicate title from a time window. The trending
    /// use-case takes two windows (recent / baseline) and computes
    /// term-frequency lift between them in pure Rust — keeping the SQL
    /// dumb makes it easy to test.
    async fn titles_in_window(&self, since: &str, before: &str) -> DomainResult<Vec<String>>;

    /// Read the cached scraped body of an article, or `None` if we've
    /// never scraped it. The in-app reader populates this on first
    /// open and cached forever after — publishers' HTML rarely changes
    /// once published, and the bandwidth saving is significant.
    async fn full_text(&self, id: i64) -> DomainResult<Option<String>>;

    /// Persist the scraped body. Idempotent — overwrites if already set.
    async fn set_full_text(&self, id: i64, full_text: &str) -> DomainResult<()>;
}
