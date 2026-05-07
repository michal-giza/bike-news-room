//! SQLite-backed implementations of `ArticleRepository` and `FeedRepository`.

use async_trait::async_trait;
use sqlx::SqlitePool;

use crate::domain::entities::{
    Article, ArticleDraft, ArticleQuery, CategoryCount, Feed, Race, RaceDraft, SourceCandidate,
    Subscriber,
};
use crate::domain::errors::DomainResult;
use crate::domain::ports::{
    ArticleRepository, FeedRepository, RaceLinkRepository, RaceRepository,
    SourceCandidateRepository, SubscriberRepository,
};

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

    // Idempotent migrations for the staleness-detection feature. Each
    // ALTER COLUMN is wrapped in `.ok()` so a re-run of init_schema on a
    // DB that already has the column doesn't panic. SQLite rejects
    // duplicate ADD COLUMN; the .ok() swallows that one specific case.
    sqlx::query(
        "ALTER TABLE feeds ADD COLUMN consecutive_empty_fetches INTEGER NOT NULL DEFAULT 0",
    )
    .execute(pool)
    .await
    .ok();
    sqlx::query("ALTER TABLE feeds ADD COLUMN last_nonempty_at TEXT")
        .execute(pool)
        .await
        .ok();
    sqlx::query("ALTER TABLE feeds ADD COLUMN dead_reason TEXT")
        .execute(pool)
        .await
        .ok();

    // v1.3 — in-app reader cache. Articles' scraped body is stored on
    // first read so subsequent readers don't re-fetch the publisher
    // every time. NULL until the user opens the article in reader mode.
    sqlx::query("ALTER TABLE articles ADD COLUMN full_text TEXT")
        .execute(pool)
        .await
        .ok();

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
        "CREATE TABLE IF NOT EXISTS source_candidates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            domain TEXT NOT NULL UNIQUE,
            mention_count INTEGER NOT NULL DEFAULT 1,
            first_seen_at TEXT NOT NULL DEFAULT (datetime('now')),
            last_seen_at TEXT NOT NULL DEFAULT (datetime('now')),
            sample_url TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            promoted_feed_id INTEGER REFERENCES feeds(id)
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS live_ticker_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            race_name TEXT NOT NULL,
            headline TEXT NOT NULL,
            kind TEXT NOT NULL DEFAULT 'update',
            source_url TEXT,
            posted_at TEXT NOT NULL DEFAULT (datetime('now'))
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS tweeted_articles (
            article_id INTEGER PRIMARY KEY REFERENCES articles(id),
            tweeted_at TEXT NOT NULL DEFAULT (datetime('now')),
            tweet_id TEXT
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS subscribers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            status TEXT NOT NULL DEFAULT 'pending',
            confirm_token TEXT NOT NULL UNIQUE,
            unsubscribe_token TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            confirmed_at TEXT
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS tracked_races (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            race_slug TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            discipline TEXT NOT NULL DEFAULT 'all',
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS race_articles (
            tracked_race_id INTEGER NOT NULL REFERENCES tracked_races(id),
            article_id INTEGER NOT NULL REFERENCES articles(id),
            matched_at TEXT NOT NULL DEFAULT (datetime('now')),
            matched_alias TEXT,
            PRIMARY KEY (tracked_race_id, article_id)
        )",
    )
    .execute(pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS wiki_context (
            cache_key TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            extract TEXT NOT NULL,
            source_url TEXT NOT NULL,
            thumbnail_url TEXT,
            lang TEXT NOT NULL,
            fetched_at TEXT NOT NULL
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
        "CREATE INDEX IF NOT EXISTS idx_source_candidates_status ON source_candidates(status, mention_count DESC)",
        "CREATE INDEX IF NOT EXISTS idx_subscribers_status ON subscribers(status)",
        "CREATE INDEX IF NOT EXISTS idx_live_ticker_posted ON live_ticker_entries(posted_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_race_articles_race ON race_articles(tracked_race_id, matched_at DESC)",
        "CREATE INDEX IF NOT EXISTS idx_race_articles_article ON race_articles(article_id)",
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

        // Multi-value filters take precedence over their single-value
        // siblings — the bg-poller uses `disciplines=` to fetch all of
        // a user's subscribed disciplines in one call. We build the IN
        // clause dynamically with bound `?` placeholders so SQLite can
        // still use its column indices and so it's safe against SQLi.
        if !q.disciplines.is_empty() {
            let placeholders = std::iter::repeat_n("?", q.disciplines.len())
                .collect::<Vec<_>>()
                .join(",");
            where_clauses.push(Box::leak(
                format!("a.discipline IN ({placeholders})").into_boxed_str(),
            ));
            for d in &q.disciplines {
                binds.push(d.clone());
            }
        } else if let Some(ref discipline) = q.discipline {
            where_clauses.push("a.discipline = ?");
            binds.push(discipline.clone());
        }
        if !q.regions.is_empty() {
            let placeholders = std::iter::repeat_n("?", q.regions.len())
                .collect::<Vec<_>>()
                .join(",");
            where_clauses.push(Box::leak(
                format!("a.region IN ({placeholders})").into_boxed_str(),
            ));
            for r in &q.regions {
                binds.push(r.clone());
            }
        } else if let Some(ref region) = q.region {
            where_clauses.push("a.region = ?");
            binds.push(region.clone());
        }
        if let Some(ref category) = q.category {
            where_clauses.push("a.category = ?");
            binds.push(category.clone());
        }
        if let Some(ref search) = q.search {
            // SQLite's LIKE treats `%`, `_`, and the escape char itself as wildcards.
            // Escape them with `\` and tell SQLite via `ESCAPE '\\'` so a search
            // for "100%" finds the literal substring instead of "anything".
            where_clauses.push("(a.title LIKE ? ESCAPE '\\' OR a.description LIKE ? ESCAPE '\\')");
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
        if let Some(ref before) = q.before {
            where_clauses.push("a.published_at < ?");
            binds.push(before.clone());
        }

        // Race-slug join expands the FROM clause rather than the WHERE
        // clause — keeps the index-friendly `idx_race_articles_race`
        // path active. We branch the SQL template so the non-race
        // common case stays a single-table scan.
        let from_clause = if q.race_slug.is_some() {
            "FROM articles a
             JOIN race_articles ra ON ra.article_id = a.id
             JOIN tracked_races tr ON tr.id = ra.tracked_race_id"
        } else {
            "FROM articles a"
        };
        if let Some(ref slug) = q.race_slug {
            where_clauses.push("tr.race_slug = ?");
            binds.push(slug.clone());
        }

        let where_str = where_clauses.join(" AND ");
        let offset = (q.page - 1) * q.limit;

        // Subquery for cluster_count is cheap because canonical_id has the
        // standard rowid-based index access pattern.
        let query_sql = format!(
            "SELECT a.*,
                (SELECT COUNT(*) FROM articles d WHERE d.canonical_id = a.id) AS cluster_count
             {from_clause}
             WHERE {where_str}
             ORDER BY a.published_at DESC
             LIMIT ? OFFSET ?"
        );
        let count_sql = format!("SELECT COUNT(*) {from_clause} WHERE {where_str}");

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

    async fn titles_in_window(&self, since: &str, before: &str) -> DomainResult<Vec<String>> {
        let rows = sqlx::query_scalar::<_, String>(
            "SELECT title FROM articles
             WHERE is_duplicate = 0
               AND published_at >= ?
               AND published_at < ?",
        )
        .bind(since)
        .bind(before)
        .fetch_all(&self.pool)
        .await?;
        Ok(rows)
    }

    async fn full_text(&self, id: i64) -> DomainResult<Option<String>> {
        let opt =
            sqlx::query_scalar::<_, Option<String>>("SELECT full_text FROM articles WHERE id = ?")
                .bind(id)
                .fetch_optional(&self.pool)
                .await?;
        Ok(opt.flatten())
    }

    async fn set_full_text(&self, id: i64, full_text: &str) -> DomainResult<()> {
        sqlx::query("UPDATE articles SET full_text = ? WHERE id = ?")
            .bind(full_text)
            .bind(id)
            .execute(&self.pool)
            .await?;
        Ok(())
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

    async fn record_fetch_yield(&self, feed_id: i64, new_count: usize) -> DomainResult<()> {
        if new_count > 0 {
            // Yielded — reset streak + stamp the last-non-empty marker.
            sqlx::query(
                "UPDATE feeds
                 SET consecutive_empty_fetches = 0,
                     last_nonempty_at = datetime('now')
                 WHERE id = ?",
            )
            .bind(feed_id)
            .execute(&self.pool)
            .await?;
        } else {
            sqlx::query(
                "UPDATE feeds SET consecutive_empty_fetches = consecutive_empty_fetches + 1
                 WHERE id = ?",
            )
            .bind(feed_id)
            .execute(&self.pool)
            .await?;
        }
        Ok(())
    }

    async fn mark_dead(&self, feed_id: i64, reason: &str) -> DomainResult<()> {
        sqlx::query("UPDATE feeds SET dead_reason = ?, active = 0 WHERE id = ?")
            .bind(reason)
            .bind(feed_id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn list_stale(&self, min_empty_streak: i32) -> DomainResult<Vec<Feed>> {
        let rows = sqlx::query_as::<_, Feed>(
            "SELECT * FROM feeds
             WHERE consecutive_empty_fetches >= ?
               AND dead_reason IS NULL
               AND active = 1
             ORDER BY consecutive_empty_fetches DESC",
        )
        .bind(min_empty_streak)
        .fetch_all(&self.pool)
        .await?;
        Ok(rows)
    }

    async fn list_dead(&self) -> DomainResult<Vec<Feed>> {
        let rows = sqlx::query_as::<_, Feed>(
            "SELECT * FROM feeds WHERE dead_reason IS NOT NULL ORDER BY title ASC",
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(rows)
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

    async fn past_races(&self, discipline: Option<&str>, limit: i64) -> DomainResult<Vec<Race>> {
        let today = chrono::Utc::now().format("%Y-%m-%d").to_string();
        let races = match discipline {
            Some(d) => {
                sqlx::query_as::<_, Race>(
                    "SELECT * FROM races
                     WHERE start_date < ? AND discipline = ?
                     ORDER BY start_date DESC LIMIT ?",
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
                     WHERE start_date < ?
                     ORDER BY start_date DESC LIMIT ?",
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
        Ok(sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM races")
            .fetch_one(&self.pool)
            .await?)
    }
}

#[async_trait]
impl SourceCandidateRepository for SqliteRepository {
    async fn record_mention(&self, domain: &str, sample_url: &str) -> DomainResult<()> {
        // Single round-trip upsert: insert new domain or bump count + refresh
        // last_seen_at if it already exists. We deliberately do NOT touch the
        // sample_url on conflict — the first URL we saw is fine to keep.
        sqlx::query(
            "INSERT INTO source_candidates (domain, sample_url)
             VALUES (?, ?)
             ON CONFLICT(domain) DO UPDATE SET
               mention_count = mention_count + 1,
               last_seen_at = datetime('now')",
        )
        .bind(domain)
        .bind(sample_url)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn list_pending(
        &self,
        min_mentions: i64,
        limit: i64,
    ) -> DomainResult<Vec<SourceCandidate>> {
        let rows = sqlx::query_as::<_, SourceCandidate>(
            "SELECT id, domain, mention_count, first_seen_at, last_seen_at,
                    sample_url, status, promoted_feed_id
             FROM source_candidates
             WHERE status = 'pending' AND mention_count >= ?
             ORDER BY mention_count DESC, last_seen_at DESC
             LIMIT ?",
        )
        .bind(min_mentions)
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;
        Ok(rows)
    }

    async fn find(&self, id: i64) -> DomainResult<Option<SourceCandidate>> {
        let row = sqlx::query_as::<_, SourceCandidate>(
            "SELECT id, domain, mention_count, first_seen_at, last_seen_at,
                    sample_url, status, promoted_feed_id
             FROM source_candidates WHERE id = ?",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row)
    }

    async fn mark_approved(&self, id: i64, feed_id: i64) -> DomainResult<()> {
        sqlx::query(
            "UPDATE source_candidates
             SET status = 'approved', promoted_feed_id = ?
             WHERE id = ?",
        )
        .bind(feed_id)
        .bind(id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn mark_rejected(&self, id: i64) -> DomainResult<()> {
        sqlx::query("UPDATE source_candidates SET status = 'rejected' WHERE id = ?")
            .bind(id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn domain_already_known(&self, domain: &str) -> DomainResult<bool> {
        // A domain "exists" if any registered feed URL contains it OR if there
        // is already an approved/rejected candidate. We deliberately allow
        // pending candidates to keep accumulating mentions.
        let in_feeds: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM feeds WHERE url LIKE ?")
            .bind(format!("%{domain}%"))
            .fetch_one(&self.pool)
            .await?;
        if in_feeds > 0 {
            return Ok(true);
        }

        let adjudicated: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM source_candidates
             WHERE domain = ? AND status IN ('approved','rejected')",
        )
        .bind(domain)
        .fetch_one(&self.pool)
        .await?;
        Ok(adjudicated > 0)
    }
}

#[async_trait]
impl SubscriberRepository for SqliteRepository {
    async fn upsert_pending(
        &self,
        email: &str,
        confirm_token: &str,
        unsubscribe_token: &str,
    ) -> DomainResult<Subscriber> {
        // ON CONFLICT keeps the original tokens intact for idempotency: if the
        // user clicks signup twice we re-send the original confirmation
        // instead of issuing a fresh token (which would invalidate any link
        // already in flight).
        sqlx::query(
            "INSERT INTO subscribers (email, confirm_token, unsubscribe_token)
             VALUES (?, ?, ?)
             ON CONFLICT(email) DO NOTHING",
        )
        .bind(email)
        .bind(confirm_token)
        .bind(unsubscribe_token)
        .execute(&self.pool)
        .await?;

        let row = sqlx::query_as::<_, Subscriber>(
            "SELECT id, email, status, confirm_token, unsubscribe_token,
                    created_at, confirmed_at
             FROM subscribers WHERE email = ?",
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;
        Ok(row)
    }

    async fn find_by_confirm_token(&self, token: &str) -> DomainResult<Option<Subscriber>> {
        let row = sqlx::query_as::<_, Subscriber>(
            "SELECT id, email, status, confirm_token, unsubscribe_token,
                    created_at, confirmed_at
             FROM subscribers WHERE confirm_token = ?",
        )
        .bind(token)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row)
    }

    async fn find_by_unsubscribe_token(&self, token: &str) -> DomainResult<Option<Subscriber>> {
        let row = sqlx::query_as::<_, Subscriber>(
            "SELECT id, email, status, confirm_token, unsubscribe_token,
                    created_at, confirmed_at
             FROM subscribers WHERE unsubscribe_token = ?",
        )
        .bind(token)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row)
    }

    async fn mark_confirmed(&self, id: i64) -> DomainResult<()> {
        sqlx::query(
            "UPDATE subscribers
             SET status = 'active', confirmed_at = datetime('now')
             WHERE id = ? AND status = 'pending'",
        )
        .bind(id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn mark_unsubscribed(&self, id: i64) -> DomainResult<()> {
        sqlx::query("UPDATE subscribers SET status = 'unsubscribed' WHERE id = ?")
            .bind(id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn list_active(&self) -> DomainResult<Vec<Subscriber>> {
        let rows = sqlx::query_as::<_, Subscriber>(
            "SELECT id, email, status, confirm_token, unsubscribe_token,
                    created_at, confirmed_at
             FROM subscribers WHERE status = 'active'",
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(rows)
    }
}

#[async_trait]
impl RaceLinkRepository for SqliteRepository {
    async fn upsert_tracked_race(
        &self,
        slug: &str,
        display_name: &str,
        discipline: &str,
    ) -> DomainResult<i64> {
        // Two-step upsert: try to find first; if missing, insert. We
        // can't use `INSERT OR IGNORE … RETURNING id` because the
        // returning is `Option<i64>` of `None` when the row already
        // exists, and we still need the existing id. SQLite's
        // `RETURNING` doesn't fire on the IGNORE path.
        if let Some(id) =
            sqlx::query_scalar::<_, i64>("SELECT id FROM tracked_races WHERE race_slug = ?")
                .bind(slug)
                .fetch_optional(&self.pool)
                .await?
        {
            // Refresh display name + discipline in case the catalogue
            // file changed between deploys.
            sqlx::query("UPDATE tracked_races SET display_name = ?, discipline = ? WHERE id = ?")
                .bind(display_name)
                .bind(discipline)
                .bind(id)
                .execute(&self.pool)
                .await?;
            return Ok(id);
        }

        let id: i64 = sqlx::query_scalar(
            "INSERT INTO tracked_races (race_slug, display_name, discipline)
             VALUES (?, ?, ?)
             RETURNING id",
        )
        .bind(slug)
        .bind(display_name)
        .bind(discipline)
        .fetch_one(&self.pool)
        .await?;
        Ok(id)
    }

    async fn link_article(
        &self,
        tracked_race_id: i64,
        article_id: i64,
        matched_alias: &str,
    ) -> DomainResult<()> {
        sqlx::query(
            "INSERT OR IGNORE INTO race_articles
                (tracked_race_id, article_id, matched_alias)
             VALUES (?, ?, ?)",
        )
        .bind(tracked_race_id)
        .bind(article_id)
        .bind(matched_alias)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    async fn list_articles_for_race(
        &self,
        race_slug: &str,
        limit: i64,
        before: Option<&str>,
    ) -> DomainResult<Vec<i64>> {
        let limit = limit.clamp(1, 500);
        let rows: Vec<i64> = if let Some(before_ts) = before {
            sqlx::query_scalar(
                "SELECT a.id
                 FROM articles a
                 JOIN race_articles ra ON ra.article_id = a.id
                 JOIN tracked_races tr ON tr.id = ra.tracked_race_id
                 WHERE tr.race_slug = ? AND a.published_at < ?
                   AND a.is_duplicate = 0
                 ORDER BY a.published_at DESC
                 LIMIT ?",
            )
            .bind(race_slug)
            .bind(before_ts)
            .bind(limit)
            .fetch_all(&self.pool)
            .await?
        } else {
            sqlx::query_scalar(
                "SELECT a.id
                 FROM articles a
                 JOIN race_articles ra ON ra.article_id = a.id
                 JOIN tracked_races tr ON tr.id = ra.tracked_race_id
                 WHERE tr.race_slug = ? AND a.is_duplicate = 0
                 ORDER BY a.published_at DESC
                 LIMIT ?",
            )
            .bind(race_slug)
            .bind(limit)
            .fetch_all(&self.pool)
            .await?
        };
        Ok(rows)
    }

    async fn count_articles_for_race(&self, race_slug: &str) -> DomainResult<i64> {
        let n: i64 = sqlx::query_scalar(
            "SELECT COUNT(*)
             FROM race_articles ra
             JOIN tracked_races tr ON tr.id = ra.tracked_race_id
             WHERE tr.race_slug = ?",
        )
        .bind(race_slug)
        .fetch_one(&self.pool)
        .await?;
        Ok(n)
    }
}
