//! Tests for application-layer use cases. Mocks every port — no I/O, fast.
//! This is the payoff of clean architecture: we can test orchestration logic
//! (circuit breaker, dedup pipeline) in isolation from HTTP, DB, and the network.

use std::sync::{Arc, Mutex};

use async_trait::async_trait;
use bike_news_room::application::IngestFeedsUseCase;
use bike_news_room::domain::entities::{Article, ArticleDraft, ArticleQuery, CategoryCount, Feed};
use bike_news_room::domain::errors::DomainResult;
use bike_news_room::domain::ports::{
    ArticleRepository, FeedFetcher, FeedRepository, FetchedFeed, FetchedItem,
};
use bike_news_room::infrastructure::FeedSource;

// ─── Mocks ──────────────────────────────────────────────────────────────

#[derive(Default)]
struct MockArticleRepo {
    articles: Mutex<Vec<Article>>,
    next_id: Mutex<i64>,
}

impl MockArticleRepo {
    fn new() -> Arc<Self> {
        Arc::new(Self {
            articles: Mutex::new(Vec::new()),
            next_id: Mutex::new(1),
        })
    }
    fn count_inserted(&self) -> usize {
        self.articles.lock().unwrap().len()
    }
}

#[async_trait]
impl ArticleRepository for MockArticleRepo {
    async fn insert(&self, draft: &ArticleDraft) -> DomainResult<Option<i64>> {
        let mut articles = self.articles.lock().unwrap();
        let mut next_id = self.next_id.lock().unwrap();

        if articles
            .iter()
            .any(|a| a.url == draft.url || a.title_hash == draft.title_hash)
        {
            return Ok(None);
        }
        let id = *next_id;
        *next_id += 1;
        articles.push(Article {
            id,
            feed_id: draft.feed_id,
            title: draft.title.clone(),
            description: draft.description.clone(),
            url: draft.url.clone(),
            image_url: draft.image_url.clone(),
            published_at: draft.published_at.clone(),
            fetched_at: None,
            title_hash: draft.title_hash.clone(),
            category: draft.category.clone(),
            region: Some(draft.region.clone()),
            discipline: Some(draft.discipline.clone()),
            language: Some(draft.language.clone()),
            is_duplicate: 0,
            canonical_id: None,
            cluster_count: 0,
        });
        Ok(Some(id))
    }
    async fn url_exists(&self, url: &str) -> DomainResult<bool> {
        Ok(self.articles.lock().unwrap().iter().any(|a| a.url == url))
    }
    async fn hash_exists(&self, hash: &str) -> DomainResult<bool> {
        Ok(self
            .articles
            .lock()
            .unwrap()
            .iter()
            .any(|a| a.title_hash == hash))
    }
    async fn mark_duplicate(&self, _: i64, _: i64) -> DomainResult<()> {
        Ok(())
    }
    async fn recent_titles(&self, _: &str) -> DomainResult<Vec<(i64, String)>> {
        Ok(vec![])
    }
    async fn query(&self, _: &ArticleQuery) -> DomainResult<(Vec<Article>, i64)> {
        let articles = self.articles.lock().unwrap().clone();
        let total = articles.len() as i64;
        Ok((articles, total))
    }
    async fn find_by_id(&self, id: i64) -> DomainResult<Option<Article>> {
        Ok(self
            .articles
            .lock()
            .unwrap()
            .iter()
            .find(|a| a.id == id)
            .cloned())
    }
    async fn count(&self) -> DomainResult<i64> {
        Ok(self.articles.lock().unwrap().len() as i64)
    }
    async fn category_counts(&self) -> DomainResult<Vec<CategoryCount>> {
        Ok(vec![])
    }
    async fn cluster_for(&self, canonical_id: i64) -> DomainResult<Vec<Article>> {
        Ok(self
            .articles
            .lock()
            .unwrap()
            .iter()
            .filter(|a| a.canonical_id == Some(canonical_id))
            .cloned()
            .collect())
    }
}

#[derive(Default)]
struct MockFeedRepo {
    feeds: Mutex<Vec<Feed>>,
    next_id: Mutex<i64>,
    increment_calls: Mutex<i64>,
    mark_fetched_calls: Mutex<i64>,
}

impl MockFeedRepo {
    fn new() -> Arc<Self> {
        Arc::new(Self {
            feeds: Mutex::new(Vec::new()),
            next_id: Mutex::new(1),
            increment_calls: Mutex::new(0),
            mark_fetched_calls: Mutex::new(0),
        })
    }
    fn set_error_count(&self, feed_id: i64, count: i32) {
        let mut feeds = self.feeds.lock().unwrap();
        if let Some(f) = feeds.iter_mut().find(|f| f.id == feed_id) {
            f.error_count = count;
        }
    }
    fn increment_count(&self) -> i64 {
        *self.increment_calls.lock().unwrap()
    }
    fn mark_fetched_count(&self) -> i64 {
        *self.mark_fetched_calls.lock().unwrap()
    }
}

#[async_trait]
impl FeedRepository for MockFeedRepo {
    async fn upsert(
        &self,
        url: &str,
        title: &str,
        region: &str,
        discipline: &str,
        language: &str,
    ) -> DomainResult<i64> {
        let mut feeds = self.feeds.lock().unwrap();
        if let Some(existing) = feeds.iter().find(|f| f.url == url) {
            return Ok(existing.id);
        }
        let mut next_id = self.next_id.lock().unwrap();
        let id = *next_id;
        *next_id += 1;
        feeds.push(Feed {
            id,
            url: url.into(),
            title: title.into(),
            region: region.into(),
            discipline: Some(discipline.into()),
            language: Some(language.into()),
            last_fetched_at: None,
            error_count: 0,
            active: 1,
        });
        Ok(id)
    }
    async fn mark_fetched(&self, feed_id: i64) -> DomainResult<()> {
        *self.mark_fetched_calls.lock().unwrap() += 1;
        let mut feeds = self.feeds.lock().unwrap();
        if let Some(f) = feeds.iter_mut().find(|f| f.id == feed_id) {
            f.error_count = 0;
            f.last_fetched_at = Some("now".into());
        }
        Ok(())
    }
    async fn increment_error(&self, feed_id: i64) -> DomainResult<()> {
        *self.increment_calls.lock().unwrap() += 1;
        let mut feeds = self.feeds.lock().unwrap();
        if let Some(f) = feeds.iter_mut().find(|f| f.id == feed_id) {
            f.error_count += 1;
        }
        Ok(())
    }
    async fn list_all(&self) -> DomainResult<Vec<Feed>> {
        Ok(self.feeds.lock().unwrap().clone())
    }
    async fn find_feed(&self, id: i64) -> DomainResult<Option<Feed>> {
        Ok(self
            .feeds
            .lock()
            .unwrap()
            .iter()
            .find(|f| f.id == id)
            .cloned())
    }
    async fn last_fetch_time(&self) -> DomainResult<Option<String>> {
        Ok(None)
    }
}

struct MockFeedFetcher {
    response: DomainResult<FetchedFeed>,
}

#[async_trait]
impl FeedFetcher for MockFeedFetcher {
    async fn fetch(&self, _url: &str) -> DomainResult<FetchedFeed> {
        match &self.response {
            Ok(f) => Ok(f.clone()),
            Err(e) => Err(match e {
                bike_news_room::domain::errors::DomainError::FeedFetch(s) => {
                    bike_news_room::domain::errors::DomainError::FeedFetch(s.clone())
                }
                _ => bike_news_room::domain::errors::DomainError::FeedFetch("mock error".into()),
            }),
        }
    }
}

fn source(url: &str) -> FeedSource {
    FeedSource {
        url: url.into(),
        title: format!("Test {url}"),
        region: "world".into(),
        discipline: "road".into(),
        language: "en".into(),
    }
}

fn item(title: &str, link: &str) -> FetchedItem {
    FetchedItem {
        title: title.into(),
        link: link.into(),
        description: Some("desc".into()),
        image_url: None,
        published_at: "2026-05-01T12:00:00+00:00".into(),
    }
}

// ─── Tests ──────────────────────────────────────────────────────────────

#[tokio::test]
async fn ingest_inserts_new_articles() {
    let article_repo = MockArticleRepo::new();
    let feed_repo = MockFeedRepo::new();
    let fetcher = Arc::new(MockFeedFetcher {
        response: Ok(FetchedFeed {
            items: vec![
                item("First article", "https://test/1"),
                item("Second article", "https://test/2"),
            ],
        }),
    });

    let uc = IngestFeedsUseCase::new(fetcher, article_repo.clone(), feed_repo.clone());
    let count = uc.execute(&[source("https://test/feed")]).await;

    assert_eq!(count, 2);
    assert_eq!(article_repo.count_inserted(), 2);
    assert_eq!(feed_repo.mark_fetched_count(), 1);
}

#[tokio::test]
async fn ingest_skips_existing_urls() {
    let article_repo = MockArticleRepo::new();
    let feed_repo = MockFeedRepo::new();
    let fetcher = Arc::new(MockFeedFetcher {
        response: Ok(FetchedFeed {
            items: vec![item("Same article", "https://test/dup")],
        }),
    });

    let uc = IngestFeedsUseCase::new(fetcher, article_repo.clone(), feed_repo.clone());
    let first = uc.execute(&[source("https://test/feed")]).await;
    let second = uc.execute(&[source("https://test/feed")]).await;

    assert_eq!(first, 1);
    assert_eq!(second, 0);
    assert_eq!(article_repo.count_inserted(), 1);
}

#[tokio::test]
async fn ingest_increments_error_on_fetch_failure() {
    let article_repo = MockArticleRepo::new();
    let feed_repo = MockFeedRepo::new();
    let fetcher = Arc::new(MockFeedFetcher {
        response: Err(bike_news_room::domain::errors::DomainError::FeedFetch(
            "boom".into(),
        )),
    });

    let uc = IngestFeedsUseCase::new(fetcher, article_repo.clone(), feed_repo.clone());
    uc.execute(&[source("https://broken/feed")]).await;

    assert_eq!(feed_repo.increment_count(), 1);
    assert_eq!(feed_repo.mark_fetched_count(), 0);
    assert_eq!(article_repo.count_inserted(), 0);
}

#[tokio::test]
async fn circuit_breaker_skips_feeds_at_threshold() {
    let article_repo = MockArticleRepo::new();
    let feed_repo = MockFeedRepo::new();

    // Pre-register the feed and set its error count above the disabled threshold.
    let feed_id = feed_repo
        .upsert("https://broken/feed", "Broken", "world", "road", "en")
        .await
        .unwrap();
    feed_repo.set_error_count(feed_id, 15);

    let fetcher = Arc::new(MockFeedFetcher {
        response: Ok(FetchedFeed {
            items: vec![item("Should not be inserted", "https://broken/x")],
        }),
    });

    let uc = IngestFeedsUseCase::new(fetcher, article_repo.clone(), feed_repo.clone());
    let count = uc.execute(&[source("https://broken/feed")]).await;

    // Skipped — no articles inserted, fetcher never called (and even if it had,
    // we wouldn't have inserted because process_one returned None).
    assert_eq!(count, 0);
    assert_eq!(article_repo.count_inserted(), 0);
}

#[tokio::test]
async fn circuit_breaker_does_not_skip_below_threshold() {
    let article_repo = MockArticleRepo::new();
    let feed_repo = MockFeedRepo::new();

    let feed_id = feed_repo
        .upsert("https://flaky/feed", "Flaky", "world", "road", "en")
        .await
        .unwrap();
    feed_repo.set_error_count(feed_id, 9); // degraded but still active

    let fetcher = Arc::new(MockFeedFetcher {
        response: Ok(FetchedFeed {
            items: vec![item("Recovered article", "https://flaky/1")],
        }),
    });

    let uc = IngestFeedsUseCase::new(fetcher, article_repo.clone(), feed_repo.clone());
    let count = uc.execute(&[source("https://flaky/feed")]).await;

    assert_eq!(count, 1);
    assert_eq!(article_repo.count_inserted(), 1);
}
