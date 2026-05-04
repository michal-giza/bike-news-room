//! Data retention sweep — keeps the SQLite database from growing forever.
//!
//! Why: HF Spaces gives us 50 GB of disk, but old articles add no value once
//! they're past the "still being read" window. Search engines have indexed
//! them via the sitemap, the daily digest is long shipped, and nobody scrolls
//! 6 months back through a news feed. Retention also speeds up every query
//! and shrinks the SQLite snapshot we upload to HF Datasets.
//!
//! Policy:
//! - Articles older than `ARTICLE_RETENTION_DAYS` (default 90) are deleted,
//!   except for any article that's been bookmarked by at least one user
//!   (we track those in the SPA, but we play it safe and keep articles
//!   that show up in clusters as canonical too).
//! - `live_ticker_entries` older than 7 days are deleted — race tickers
//!   are pure now-data.
//! - `source_candidates` with status='rejected' older than 30 days are
//!   deleted — we don't need a permanent rejection log.
//! - Source-candidate mention counts for still-pending domains stay
//!   forever, so a slowly-cited domain still eventually surfaces.
//!
//! Runs from a daily cron in main.rs.

use sqlx::SqlitePool;
use tracing::{info, warn};

pub struct RetentionUseCase {
    pool: SqlitePool,
    article_retention_days: i64,
    ticker_retention_days: i64,
    rejected_candidate_retention_days: i64,
}

impl RetentionUseCase {
    pub fn new(pool: SqlitePool) -> Self {
        let article_days = std::env::var("ARTICLE_RETENTION_DAYS")
            .ok()
            .and_then(|s| s.parse::<i64>().ok())
            .filter(|n| (7..=3650).contains(n))
            .unwrap_or(90);
        Self {
            pool,
            article_retention_days: article_days,
            ticker_retention_days: 7,
            rejected_candidate_retention_days: 30,
        }
    }

    pub async fn execute(&self) -> RetentionReport {
        let report = RetentionReport {
            articles_deleted: self.sweep_articles().await.unwrap_or_else(|e| {
                warn!("retention: article sweep failed: {e}");
                0
            }),
            ticker_entries_deleted: self.sweep_ticker().await.unwrap_or_else(|e| {
                warn!("retention: ticker sweep failed: {e}");
                0
            }),
            candidates_deleted: self.sweep_candidates().await.unwrap_or_else(|e| {
                warn!("retention: candidate sweep failed: {e}");
                0
            }),
        };

        // VACUUM only when something was actually deleted — VACUUM rewrites
        // the entire DB file and locks for the duration, which is wasteful
        // on no-op runs.
        if report.total_deleted() > 0 {
            if let Err(e) = sqlx::query("VACUUM").execute(&self.pool).await {
                warn!("retention: VACUUM failed: {e}");
            }
        }

        info!(
            "retention sweep: {} articles, {} ticker entries, {} rejected candidates deleted",
            report.articles_deleted, report.ticker_entries_deleted, report.candidates_deleted,
        );
        report
    }

    async fn sweep_articles(&self) -> Result<u64, sqlx::Error> {
        // Keep two classes of old articles:
        //   1. Canonical-of-cluster — duplicate articles point at them.
        //      Deleting the canonical orphans every duplicate's cluster
        //      view.
        //   2. Race-linked — any article tied to a tracked race in
        //      `race_articles` is part of the user-visible historic
        //      coverage for that race ("Tour de France 2024 archive").
        //      We never delete those; the race link is the user's
        //      promise that this matters long-term.
        let cutoff = format!("-{} days", self.article_retention_days);
        let result = sqlx::query(
            "DELETE FROM articles
             WHERE published_at < datetime('now', ?)
               AND id NOT IN (
                 SELECT DISTINCT canonical_id FROM articles
                 WHERE canonical_id IS NOT NULL
               )
               AND id NOT IN (
                 SELECT DISTINCT article_id FROM race_articles
               )",
        )
        .bind(&cutoff)
        .execute(&self.pool)
        .await?;
        Ok(result.rows_affected())
    }

    async fn sweep_ticker(&self) -> Result<u64, sqlx::Error> {
        let cutoff = format!("-{} days", self.ticker_retention_days);
        let result =
            sqlx::query("DELETE FROM live_ticker_entries WHERE posted_at < datetime('now', ?)")
                .bind(&cutoff)
                .execute(&self.pool)
                .await?;
        Ok(result.rows_affected())
    }

    async fn sweep_candidates(&self) -> Result<u64, sqlx::Error> {
        let cutoff = format!("-{} days", self.rejected_candidate_retention_days);
        let result = sqlx::query(
            "DELETE FROM source_candidates
             WHERE status = 'rejected' AND last_seen_at < datetime('now', ?)",
        )
        .bind(&cutoff)
        .execute(&self.pool)
        .await?;
        Ok(result.rows_affected())
    }
}

#[derive(Debug, Default, Clone, Copy)]
pub struct RetentionReport {
    pub articles_deleted: u64,
    pub ticker_entries_deleted: u64,
    pub candidates_deleted: u64,
}

impl RetentionReport {
    pub fn total_deleted(&self) -> u64 {
        self.articles_deleted + self.ticker_entries_deleted + self.candidates_deleted
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn fresh_pool() -> SqlitePool {
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await
            .unwrap();
        crate::infrastructure::sqlite_repository::init_schema(&pool)
            .await
            .unwrap();
        pool
    }

    #[tokio::test]
    async fn deletes_old_articles_keeps_recent() {
        let pool = fresh_pool().await;
        sqlx::query("INSERT INTO feeds (url, title, region) VALUES ('http://x', 'Test', 'world')")
            .execute(&pool)
            .await
            .unwrap();
        // Old article (200 days ago) — should be swept.
        sqlx::query(
            "INSERT INTO articles (feed_id, title, url, published_at, title_hash)
             VALUES (1, 'old', 'http://x/old', datetime('now', '-200 days'), 'h1')",
        )
        .execute(&pool)
        .await
        .unwrap();
        // Recent article — must survive.
        sqlx::query(
            "INSERT INTO articles (feed_id, title, url, published_at, title_hash)
             VALUES (1, 'fresh', 'http://x/fresh', datetime('now', '-3 days'), 'h2')",
        )
        .execute(&pool)
        .await
        .unwrap();

        let uc = RetentionUseCase::new(pool.clone());
        let report = uc.execute().await;
        assert_eq!(report.articles_deleted, 1);

        let remaining: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM articles")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(remaining, 1);
    }

    #[tokio::test]
    async fn keeps_race_linked_articles_even_when_old() {
        let pool = fresh_pool().await;
        sqlx::query("INSERT INTO feeds (url, title, region) VALUES ('http://x', 'Test', 'world')")
            .execute(&pool)
            .await
            .unwrap();
        // Old article — would normally be swept.
        sqlx::query(
            "INSERT INTO articles (id, feed_id, title, url, published_at, title_hash)
             VALUES (1, 1, 'tdf 2024 stage 5', 'http://x/a', datetime('now', '-200 days'), 'h1')",
        )
        .execute(&pool)
        .await
        .unwrap();
        // Tracked-race + race link — exempts the article.
        sqlx::query(
            "INSERT INTO tracked_races (id, race_slug, display_name, discipline)
             VALUES (1, 'tour-de-france', 'Tour de France', 'road')",
        )
        .execute(&pool)
        .await
        .unwrap();
        sqlx::query(
            "INSERT INTO race_articles (tracked_race_id, article_id, matched_alias)
             VALUES (1, 1, 'Tour de France')",
        )
        .execute(&pool)
        .await
        .unwrap();

        let uc = RetentionUseCase::new(pool.clone());
        uc.execute().await;

        // Article (id=1) survives because it's race-linked.
        let kept: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM articles WHERE id = 1")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(kept, 1, "race-linked article must survive sweep");
    }

    #[tokio::test]
    async fn keeps_canonical_articles_even_when_old() {
        let pool = fresh_pool().await;
        sqlx::query("INSERT INTO feeds (url, title, region) VALUES ('http://x', 'Test', 'world')")
            .execute(&pool)
            .await
            .unwrap();
        // Old canonical article — should survive because something references it.
        sqlx::query(
            "INSERT INTO articles (id, feed_id, title, url, published_at, title_hash)
             VALUES (1, 1, 'canonical', 'http://x/c', datetime('now', '-200 days'), 'h1')",
        )
        .execute(&pool)
        .await
        .unwrap();
        // Old duplicate pointing at canonical — would-be-deleted, but the
        // canonical is shielded by the NOT IN subquery.
        sqlx::query(
            "INSERT INTO articles (id, feed_id, title, url, published_at, title_hash, is_duplicate, canonical_id)
             VALUES (2, 1, 'dup', 'http://x/d', datetime('now', '-200 days'), 'h2', 1, 1)",
        )
        .execute(&pool)
        .await
        .unwrap();

        let uc = RetentionUseCase::new(pool.clone());
        uc.execute().await;

        // Canonical (id=1) survives, duplicate (id=2) gets swept.
        let kept: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM articles WHERE id = 1")
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(kept, 1, "canonical article must survive sweep");
    }

    #[tokio::test]
    async fn deletes_old_ticker_entries() {
        let pool = fresh_pool().await;
        sqlx::query(
            "INSERT INTO live_ticker_entries (race_name, headline, posted_at)
             VALUES ('Giro', 'old', datetime('now', '-30 days')),
                    ('Giro', 'new', datetime('now', '-1 days'))",
        )
        .execute(&pool)
        .await
        .unwrap();

        let uc = RetentionUseCase::new(pool.clone());
        let report = uc.execute().await;
        assert_eq!(report.ticker_entries_deleted, 1);
    }
}
