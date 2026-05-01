//! Use case: crawl websites without RSS, dedupe, persist.

use std::sync::Arc;
use std::time::Duration;

use tracing::{info, warn};

use crate::domain::entities::{ArticleDraft, FeedHealth};
use crate::domain::ports::{ArticleRepository, CrawlTarget, FeedRepository, WebCrawler};
use crate::domain::services::{categorize, compute_title_hash, extract_domain, normalize_url};

pub struct CrawlSitesUseCase<C> {
    crawler: Arc<C>,
    article_repo: Arc<dyn ArticleRepository>,
    feed_repo: Arc<dyn FeedRepository>,
    delay_between_targets: Duration,
}

impl<C: WebCrawler + 'static> CrawlSitesUseCase<C> {
    pub fn new(
        crawler: Arc<C>,
        article_repo: Arc<dyn ArticleRepository>,
        feed_repo: Arc<dyn FeedRepository>,
    ) -> Self {
        Self {
            crawler,
            article_repo,
            feed_repo,
            delay_between_targets: Duration::from_secs(2),
        }
    }

    /// Politeness delay between hitting different sites. Tests can shorten this.
    #[cfg(test)]
    pub fn with_delay(mut self, delay: Duration) -> Self {
        self.delay_between_targets = delay;
        self
    }

    pub async fn execute(&self, targets: &[CrawlTarget]) -> usize {
        let mut total_new = 0;
        for target in targets {
            if let Some(n) = self.crawl_one(target).await {
                total_new += n;
            }
            tokio::time::sleep(self.delay_between_targets).await;
        }
        total_new
    }

    async fn crawl_one(&self, target: &CrawlTarget) -> Option<usize> {
        let feed_id = match self
            .feed_repo
            .upsert(
                &target.url,
                &target.name,
                &target.region,
                &target.discipline,
                &target.language,
            )
            .await
        {
            Ok(id) => id,
            Err(e) => {
                warn!("upsert crawl target {} failed: {e}", target.name);
                return Some(0);
            }
        };

        // Circuit breaker via indexed lookup — was an O(N) full feed scan.
        if let Ok(Some(feed)) = self.feed_repo.find_feed(feed_id).await {
            if FeedHealth::from_error_count(feed.error_count).should_skip() {
                info!(
                    "circuit breaker: skipping crawl '{}' ({})",
                    target.name, feed.error_count
                );
                return None;
            }
        }

        let items = match self.crawler.crawl(target).await {
            Ok(items) => items,
            Err(e) => {
                warn!("crawl '{}' failed: {e}", target.name);
                let _ = self.feed_repo.increment_error(feed_id).await;
                return Some(0);
            }
        };

        let mut new_count = 0;
        for item in &items {
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
                region: target.region.clone(),
                discipline: target.discipline.clone(),
                language: target.language.clone(),
            };

            match self.article_repo.insert(&draft).await {
                Ok(Some(_)) => new_count += 1,
                Ok(None) => {}
                Err(e) => warn!("insert crawled '{}' failed: {e}", draft.title),
            }
        }

        let _ = self.feed_repo.mark_fetched(feed_id).await;
        info!("crawled '{}': {} new articles", target.name, new_count);
        Some(new_count)
    }
}
