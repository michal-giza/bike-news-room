//! SQLite-backed implementations of `ArticleRepository` and `FeedRepository`.

use async_trait::async_trait;
use sqlx::SqlitePool;

use crate::domain::entities::{
    Article, ArticleDraft, ArticleQuery, CategoryCount, Feed, Race, RaceDraft,
};
use crate::domain::errors::DomainResult;
use crate::domain::ports::{ArticleRepository, FeedRepository, RaceRepository};

/// Initialize the schema. Idempotent — safe to call on every startup.
pub async fn init_schema(pool: &SqlitePool) -> DomainResult<()> {
    sqlx::query(
        "CREATE TABLE IF NOT EXISTS feeds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            region TEXT NOT NULL,
            discipline TEXT,
            language TEXT DEFAULT 'en',
            last_fetched_at TEXT,
            error_count INTEGER DEFAULT 0,
            active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT (datetime('now'))
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS articles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feed_id INTEGER NOT NULL REFERENCES feeds(id),
            title TEXT NOT NULL,
            description TEXT,
            url TEXT NOT NULL,
            image_url TEXT,
            published_at TEXT NOT NULL,
            fetched_at TEXT DEFAULT (datetime('now')),
            title_hash TEXT NOT NULL,
            category TEXT,
            region TEXT,
            discipline TEXT,
            language TEXT,
            is_duplicate INTEGER DEFAULT 0,
            canonical_id INTEGER REFERENCES articles(id)
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS races (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT,
            country TEXT,
            category TEXT,
            discipline TEXT NOT NULL,
            url TEXT,
            fetched_at TEXT DEFAULT (datetime('now'))
        )",
    )
    .execute(pool)
    .await?;

    for stmt in [
        "CREATE INDEX IF NOT EXISTS idx_articles_published ON articles(published_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_articles_hash ON articles(title_hash)",
        "CREATE INDEX IF NOT EXISTS idx_articles_category ON articles(category, published_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_articles_region ON articles(region, published_at DESC)",
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_articles_url ON articles(url)",
        "CREATE INDEX IF NOT EXISTS idx_races_start ON races(start_date)",
        "CREATE INDEX IF NOT EXISTS idx_races_discipline ON races(discipline, start_date)",
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_races_natural_key ON races(name, start_date)",
    ] {
        sqlx::query(stmt).execute(pool).await.ok();
    }

    Ok(())
}

#[derive(Clone)]
pub struct SqliteRepository {
    pool: SqlitePool,
}

impl SqliteRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }

    pub fn pool(&self) -> &SqlitePool {
        &self.pool
    }
}

#[async_trait]
impl ArticleRepository for SqliteRepository {
    async fn insert(&self, draft: &ArticleDraft) -> DomainResult<Option<i64>> {
        let id = sqlx::query_scalar::<_, i64>(
            "INSERT OR IGNORE INTO articles
             (feed_id, title, description, url, image_url, published_at, title_hash,
              category, region, discipline, language)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             RETURNING id",
        )
        .bind(draft.feed_id)
        .bind(&draft.title)
        .bind(&draft.description)
        .bind(&draft.url)
        .bind(&draft.image_url)
        .bind(&draft.published_at)
        .bind(&draft.title_hash)
        .bind(&draft.category)
        .bind(&draft.region)
        .bind(&draft.discipline)
        .bind(&draft.language)
        .fetch_optional(&self.pool)
        .await?;

        Ok(id)
    }

    async fn url_exists(&self, url: &str) -> DomainResult<bool> {
        let count = sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM articles WHERE url = ?")
            .bind(url)
            .fetch_one(&self.pool)
            .await?;
        Ok(count > 0)
    }

    async fn hash_exists(&self, hash: &str) -> DomainResult<bool> {
        let count =
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM articles WHERE title_hash = ?")
                .bind(hash)
                .fetch_one(&self.pool)
                .await?;
        Ok(count > 0)
    }

    async fn mark_duplicate(&self, article_id: i64, canonical_id: i64) -> DomainResult<()> {
        sqlx::query("UPDATE articles SET is_duplicate = 1, canonical_id = ? WHERE id = ?")
            .bind(canonical_id)
            .bind(article_id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn recent_titles(&self, since: &str) -> DomainResult<Vec<(i64, String)>> {
        let rows = sqlx::query_as::<_, (i64, String)>(
            "SELECT id, title FROM articles WHERE published_at > ? AND is_duplicate = 0",
        )
        .bind(since)
        .fetch_all(&self.pool)
        .await?;
        Ok(rows)
    }

    async fn query(&self, q: &ArticleQuery) -> DomainResult<(Vec<Article>, i64)> {
        // All column refs are prefixed with `a.` because the article query
        // joins a subquery for cluster_count below.
        let mut where_clauses: Vec<&'static str> = vec!["a.is_duplicate = 0"];
        let mut binds: Vec<String> = Vec::new();

        if let Some(ref region) = q.region {
            where_clauses.push("a.region = ?");
            binds.push(region.clone());
        }
        if let Some(ref discipline) = q.discipline {
            where_clauses.push("a.discipline = ?");
            binds.push(discipline.clone());
        }
        if let Some(ref category) = q.category {
            where_clauses.push("a.category = ?");
            binds.push(category.clone());
        }
        if let Some(ref search) = q.search {
            // SQLite's LIKE treats `%`, `_`, and the escape char itself as wildcards.
            // Escape them with `\` and tell SQLite via `ESCAPE '\\'` so a search
            // for "100%" finds the literal substring instead of "anything".
            where_clauses
                .push("(a.title LIKE ? ESCAPE '\\' OR a.description LIKE ? ESCAPE '\\')");
            let escaped = search
                .replace('\\', "\\\\")
                .replace('%', "\\%")
                .replace('_', "\\_");
            let pattern = format!("%{escaped}%");
            binds.push(pattern.clone());
            binds.push(pattern);
        }
        if let Some(ref since) = q.since {
            where_clauses.push("a.published_at > ?");
            binds.push(since.clone());
        }

        let where_str = where_clauses.join(" AND ");
        let offset = (q.page - 1) * q.limit;

        // Subquery for cluster_count is cheap because canonical_id has the
        // standard rowid-based index access pattern.
        let query_sql = format!(
            "SELECT a.*,
                (SELECT COUNT(*) FROM articles d WHERE d.canonical_id = a.id) AS cluster_count
             FROM articles a
             WHERE {where_str}
             ORDER BY a.published_at DESC
             LIMIT ? OFFSET ?"
        );
        let count_sql = format!("SELECT COUNT(*) FROM articles a WHERE {where_str}");

        let mut query = sqlx::query_as::<_, Article>(&query_sql);
        let mut count_query = sqlx::query_scalar::<_, i64>(&count_sql);
        for v in &binds {
            query = query.bind(v);
            count_query = count_query.bind(v);
        }
        query = query.bind(q.limit).bind(offset);

        let articles = query.fetch_all(&self.pool).await?;
        let total = count_query.fetch_one(&self.pool).await?;
        Ok((articles, total))
    }

    async fn find_by_id(&self, id: i64) -> DomainResult<Option<Article>> {
        let article = sqlx::query_as::<_, Article>(
            "SELECT a.*,
                (SELECT COUNT(*) FROM articles d WHERE d.canonical_id = a.id) AS cluster_count
             FROM articles a WHERE a.id = ?",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;
        Ok(article)
    }

    async fn count(&self) -> DomainResult<i64> {
        Ok(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM articles WHERE is_duplicate = 0")
                .fetch_one(&self.pool)
                .await?,
        )
    }

    async fn cluster_for(&self, canonical_id: i64) -> DomainResult<Vec<Article>> {
        let articles = sqlx::query_as::<_, Article>(
            "SELECT * FROM articles WHERE canonical_id = ? ORDER BY published_at DESC",
        )
        .bind(canonical_id)
        .fetch_all(&self.pool)
        .await?;
        Ok(articles)
    }

    async fn category_counts(&self) -> DomainResult<Vec<CategoryCount>> {
        let rows = sqlx::query_as::<_, (String, i64)>(
            "SELECT COALESCE(category, 'uncategorized'), COUNT(*)
             FROM articles
             WHERE is_duplicate = 0
             GROUP BY category
             ORDER BY COUNT(*) DESC",
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(category, count)| CategoryCount { category, count })
            .collect())
    }
}

#[async_trait]
impl FeedRepository for SqliteRepository {
    async fn upsert(
        &self,
        url: &str,
        title: &str,
        region: &str,
        discipline: &str,
        language: &str,
    ) -> DomainResult<i64> {
        let id = sqlx::query_scalar::<_, i64>(
            "INSERT INTO feeds (url, title, region, discipline, language)
             VALUES (?, ?, ?, ?, ?)
             ON CONFLICT(url) DO UPDATE SET title = excluded.title
             RETURNING id",
        )
        .bind(url)
        .bind(title)
        .bind(region)
        .bind(discipline)
        .bind(language)
        .fetch_one(&self.pool)
        .await?;
        Ok(id)
    }

    async fn mark_fetched(&self, feed_id: i64) -> DomainResult<()> {
        sqlx::query(
            "UPDATE feeds SET last_fetched_at = datetime('now'), error_count = 0 WHERE id = ?",
        )
        .bind(feed_id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn increment_error(&self, feed_id: i64) -> DomainResult<()> {
        sqlx::query("UPDATE feeds SET error_count = error_count + 1 WHERE id = ?")
            .bind(feed_id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn list_all(&self) -> DomainResult<Vec<Feed>> {
        let feeds = sqlx::query_as::<_, Feed>("SELECT * FROM feeds ORDER BY title")
            .fetch_all(&self.pool)
            .await?;
        Ok(feeds)
    }

    async fn find_feed(&self, id: i64) -> DomainResult<Option<Feed>> {
        let feed = sqlx::query_as::<_, Feed>("SELECT * FROM feeds WHERE id = ?")
            .bind(id)
            .fetch_optional(&self.pool)
            .await?;
        Ok(feed)
    }

    async fn last_fetch_time(&self) -> DomainResult<Option<String>> {
        let result = sqlx::query_scalar::<_, Option<String>>(
            "SELECT MAX(last_fetched_at) FROM feeds WHERE last_fetched_at IS NOT NULL",
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(result)
    }
}

#[async_trait]
impl RaceRepository for SqliteRepository {
    async fn upsert_race(&self, draft: &RaceDraft) -> DomainResult<i64> {
        let id = sqlx::query_scalar::<_, i64>(
            "INSERT INTO races (name, start_date, end_date, country, category, discipline, url, fetched_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
             ON CONFLICT(name, start_date) DO UPDATE SET
               end_date = excluded.end_date,
               country = excluded.country,
               category = excluded.category,
               discipline = excluded.discipline,
               url = excluded.url,
               fetched_at = datetime('now')
             RETURNING id",
        )
        .bind(&draft.name)
        .bind(&draft.start_date)
        .bind(&draft.end_date)
        .bind(&draft.country)
        .bind(&draft.category)
        .bind(&draft.discipline)
        .bind(&draft.url)
        .fetch_one(&self.pool)
        .await?;
        Ok(id)
    }

    async fn upcoming_races(
        &self,
        discipline: Option<&str>,
        limit: i64,
    ) -> DomainResult<Vec<Race>> {
        let today = chrono::Utc::now().format("%Y-%m-%d").to_string();
        let races = match discipline {
            Some(d) => {
                sqlx::query_as::<_, Race>(
                    "SELECT * FROM races
                     WHERE start_date >= ? AND discipline = ?
                     ORDER BY start_date ASC LIMIT ?",
                )
                .bind(&today)
                .bind(d)
                .bind(limit)
                .fetch_all(&self.pool)
                .await?
            }
            None => {
                sqlx::query_as::<_, Race>(
                    "SELECT * FROM races
                     WHERE start_date >= ?
                     ORDER BY start_date ASC LIMIT ?",
                )
                .bind(&today)
                .bind(limit)
                .fetch_all(&self.pool)
                .await?
            }
        };
        Ok(races)
    }

    async fn count_races(&self) -> DomainResult<i64> {
        Ok(
            sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM races")
                .fetch_one(&self.pool)
                .await?,
        )
    }
}
