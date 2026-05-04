//! Use case: fetch RSS feeds, deduplicate, categorize, and persist new articles.
//! Implements per-feed circuit breaker — feeds with too many errors are skipped.

use std::sync::Arc;

use chrono::Utc;
use futures::future::join_all;
use tracing::{info, warn};

use crate::application::{MineCandidatesUseCase, RaceMatcherUseCase};
use crate::domain::entities::{ArticleDraft, FeedHealth};
use crate::domain::ports::{ArticleRepository, FeedFetcher, FeedRepository};
use crate::domain::services::{
    categorize, compute_title_hash, extract_domain, is_fuzzy_duplicate, normalize_url,
};
use crate::infrastructure::FeedSource;

pub struct IngestFeedsUseCase<F> {
    fetcher: Arc<F>,
    article_repo: Arc<dyn ArticleRepository>,
    feed_repo: Arc<dyn FeedRepository>,
    miner: Option<Arc<MineCandidatesUseCase>>,
    race_matcher: Option<Arc<RaceMatcherUseCase>>,
}

impl<F: FeedFetcher + 'static> IngestFeedsUseCase<F> {
    pub fn new(
        fetcher: Arc<F>,
        article_repo: Arc<dyn ArticleRepository>,
        feed_repo: Arc<dyn FeedRepository>,
    ) -> Self {
        Self {
            fetcher,
            article_repo,
            feed_repo,
            miner: None,
            race_matcher: None,
        }
    }

    /// Attach an outbound-link miner. When set, every newly-inserted article
    /// has its description scanned for cycling-domain candidates the admin
    /// can later promote to feeds.
    pub fn with_miner(mut self, miner: Arc<MineCandidatesUseCase>) -> Self {
        self.miner = Some(miner);
        self
    }

    /// Attach the race matcher. When set, every newly-inserted article is
    /// scanned against the race catalogue and any matches are persisted to
    /// `race_articles` (which also retention-exempts the article).
    pub fn with_race_matcher(mut self, matcher: Arc<RaceMatcherUseCase>) -> Self {
        self.race_matcher = Some(matcher);
        self
    }

    /// Process a single feed source. Returns the number of new articles inserted,
    /// or `None` if the source was skipped by the circuit breaker.
    pub async fn process_one(
        &self,
        source: &FeedSource,
        recent_titles: &[(i64, String)],
    ) -> Option<usize> {
        let feed_id = match self
            .feed_repo
            .upsert(
                &source.url,
                &source.title,
                &source.region,
                &source.discipline,
                &source.language,
            )
            .await
        {
            Ok(id) => id,
            Err(e) => {
                warn!("upsert failed for {}: {e}", source.title);
                return Some(0);
            }
        };

        // Circuit breaker: check current health from the persisted error_count.
        // Uses indexed find_feed so we don't scan the whole feeds table per source.
        if let Ok(Some(feed)) = self.feed_repo.find_feed(feed_id).await {
            let health = FeedHealth::from_error_count(feed.error_count);
            if health.should_skip() {
                info!(
                    "circuit breaker: skipping '{}' (error_count={})",
                    source.title, feed.error_count
                );
                return None;
            }
        }

        let fetched = match self.fetcher.fetch(&source.url).await {
            Ok(f) => f,
            Err(e) => {
                warn!("fetch '{}' failed: {e}", source.title);
                let _ = self.feed_repo.increment_error(feed_id).await;
                return Some(0);
            }
        };

        let mut new_count = 0;
        for item in &fetched.items {
            let normalized_link = normalize_url(&item.link);

            if self
                .article_repo
                .url_exists(&normalized_link)
                .await
                .unwrap_or(false)
            {
                continue;
            }

            let domain = extract_domain(&normalized_link);
            let title_hash = compute_title_hash(&item.title, &domain, &item.published_at);

            if self
                .article_repo
                .hash_exists(&title_hash)
                .await
                .unwrap_or(false)
            {
                continue;
            }

            let category = categorize(&item.title, item.description.as_deref());

            let draft = ArticleDraft {
                feed_id,
                title: item.title.clone(),
                description: item.description.clone(),
                url: normalized_link,
                image_url: item.image_url.clone(),
                published_at: item.published_at.clone(),
                title_hash,
                category,
                region: source.region.clone(),
                discipline: source.discipline.clone(),
                language: source.language.clone(),
            };

            match self.article_repo.insert(&draft).await {
                Ok(Some(article_id)) => {
                    new_count += 1;
                    if let Some(canonical_id) = is_fuzzy_duplicate(&draft.title, recent_titles) {
                        let _ = self
                            .article_repo
                            .mark_duplicate(article_id, canonical_id)
                            .await;
                    }
                    if let Some(miner) = &self.miner {
                        miner
                            .mine_article(draft.description.as_deref(), &draft.url)
                            .await;
                    }
                    if let Some(matcher) = &self.race_matcher {
                        matcher
                            .match_and_link(
                                article_id,
                                &draft.title,
                                draft.description.as_deref(),
                                Some(&draft.discipline),
                            )
                            .await;
                    }
                }
                Ok(None) => {} // dedup'd by INSERT OR IGNORE
                Err(e) => warn!("insert '{}' failed: {e}", draft.title),
            }
        }

        let _ = self.feed_repo.mark_fetched(feed_id).await;
        info!(
            "feed '{}': {} new articles from {} entries",
            source.title,
            new_count,
            fetched.items.len()
        );
        Some(new_count)
    }

    /// Process all configured sources concurrently.
    ///
    /// `join_all` runs every per-source future at once. With ~20 sources and
    /// reqwest's default connection pool this is fine; if we ever ship 100+
    /// sources we'll switch to bounded concurrency via `buffer_unordered`.
    pub async fn execute(&self, sources: &[FeedSource]) -> usize {
        let yesterday = (Utc::now() - chrono::Duration::hours(24))
            .format("%Y-%m-%dT%H:%M:%S")
            .to_string();
        let recent = self
            .article_repo
            .recent_titles(&yesterday)
            .await
            .unwrap_or_default();

        let results: Vec<Option<usize>> = join_all(
            sources
                .iter()
                .map(|source| self.process_one(source, &recent)),
        )
        .await;

        results.into_iter().flatten().sum()
    }
}
