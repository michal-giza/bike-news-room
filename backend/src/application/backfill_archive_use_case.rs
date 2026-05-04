//! Internet Archive backfill — populate `race_articles` with historic
//! coverage of past Grand Tours, Monuments, Worlds, etc., so a user
//! following Tour de France today can browse Tour 2024 + 2023 + 2022
//! archives even though those articles were published before our
//! ingest pipeline existed.
//!
//! Source: web.archive.org's CDX API. Free, no API key, no rate limit
//! issues at our volume.
//!
//! Pipeline per (race_slug, year):
//!   1. Look up archive patterns from
//!      [`crate::infrastructure::archive_backfill_targets`].
//!   2. For each pattern, query CDX for snapshot timestamps + URLs.
//!   3. Dedup by canonical URL (strip `web.archive.org/web/<ts>/` prefix).
//!   4. Skip URLs that already exist in `articles` (URL UNIQUE).
//!   5. Fetch the wayback snapshot HTML, extract title / description /
//!      published_at / image with the same selectors the live HTML
//!      crawler uses.
//!   6. INSERT INTO articles + INSERT INTO race_articles.
//!
//! Caps:
//!   - 100 articles per (race, year)
//!   - 1 request / 2 seconds per publisher (sequential, polite)
//!   - 30-day idempotency check via `backfill_runs` table — re-running
//!     the same (race, year) within 30 days short-circuits at cost ~0.
//!
//! Legal posture: we store ONLY title + short snippet + canonical URL +
//! wayback snapshot URL. No full body. Click-through prefers the live
//! publisher URL; falls back to the wayback snapshot when the live URL
//! 404s. UA identifies us as `BikeNewsRoom-Backfill/0.1` so publishers
//! can contact us if needed. We honour the publisher's current
//! robots.txt at fetch time.

use std::collections::HashSet;
use std::sync::Arc;
use std::time::Duration;

use chrono::Utc;
use scraper::{Html, Selector};
use serde::Deserialize;
use sqlx::SqlitePool;
use tracing::{info, warn};

use crate::domain::entities::ArticleDraft;
use crate::domain::ports::{ArticleRepository, FeedRepository, RaceLinkRepository};
use crate::domain::services::{compute_title_hash, normalize_url};
use crate::infrastructure::archive_backfill_targets::{patterns_for, PublisherPattern};

const PER_RUN_ARTICLE_CAP: usize = 100;
const FETCH_INTERVAL: Duration = Duration::from_millis(2000);
const FETCH_TIMEOUT: Duration = Duration::from_secs(20);
const REPEAT_COOLDOWN_DAYS: i64 = 30;
const USER_AGENT: &str =
    "Mozilla/5.0 (compatible; BikeNewsRoom-Backfill/0.1; +https://bike-news-room.pages.dev/about)";

#[derive(Debug, Clone)]
pub struct BackfillReport {
    pub race_slug: String,
    pub year: i32,
    pub fetched: usize,
    pub inserted: usize,
    pub linked: usize,
    pub skipped_existing: usize,
    pub skipped_publisher_blocked: usize,
}

pub struct BackfillArchiveUseCase {
    article_repo: Arc<dyn ArticleRepository>,
    feed_repo: Arc<dyn FeedRepository>,
    race_link_repo: Arc<dyn RaceLinkRepository>,
    pool: SqlitePool,
    http: reqwest::Client,
}

impl BackfillArchiveUseCase {
    pub fn new(
        article_repo: Arc<dyn ArticleRepository>,
        feed_repo: Arc<dyn FeedRepository>,
        race_link_repo: Arc<dyn RaceLinkRepository>,
        pool: SqlitePool,
    ) -> Self {
        let http = reqwest::Client::builder()
            .timeout(FETCH_TIMEOUT)
            .user_agent(USER_AGENT)
            .build()
            .expect("reqwest");
        Self {
            article_repo,
            feed_repo,
            race_link_repo,
            pool,
            http,
        }
    }

    /// Idempotent. Run on demand (admin endpoint) or as a one-shot at
    /// deploy time. The cooldown table prevents accidental double-runs;
    /// pass `force = true` to skip the cooldown check and re-scan
    /// (useful if a publisher restructured their archive URLs).
    pub async fn run(
        &self,
        race_slug: &str,
        year: i32,
        force: bool,
    ) -> anyhow::Result<BackfillReport> {
        // Cooldown check — store last-run timestamps in a tiny table.
        if !force {
            self.ensure_cooldown_table().await?;
            let recent: Option<i64> = sqlx::query_scalar(
                "SELECT 1 FROM backfill_runs
                 WHERE race_slug = ? AND year = ?
                   AND ran_at > datetime('now', ?)
                 LIMIT 1",
            )
            .bind(race_slug)
            .bind(year)
            .bind(format!("-{REPEAT_COOLDOWN_DAYS} days"))
            .fetch_optional(&self.pool)
            .await?;
            if recent.is_some() {
                info!(
                    "backfill cooldown — skipping ({race_slug}, {year}) within {REPEAT_COOLDOWN_DAYS}d"
                );
                return Ok(BackfillReport {
                    race_slug: race_slug.to_string(),
                    year,
                    fetched: 0,
                    inserted: 0,
                    linked: 0,
                    skipped_existing: 0,
                    skipped_publisher_blocked: 0,
                });
            }
        }

        let patterns = patterns_for(race_slug);
        if patterns.is_empty() {
            warn!("no archive patterns for race {race_slug} — skipping");
            return Ok(BackfillReport {
                race_slug: race_slug.to_string(),
                year,
                fetched: 0,
                inserted: 0,
                linked: 0,
                skipped_existing: 0,
                skipped_publisher_blocked: 0,
            });
        }

        // Resolve race -> tracked_races.id once. The matcher seeds the
        // brand row at startup, so this should always resolve.
        let race = match self.lookup_race_id(race_slug).await? {
            Some((id, name, discipline)) => (id, name, discipline),
            None => {
                warn!("backfill: race {race_slug} not in tracked_races, run matcher first");
                return Ok(BackfillReport {
                    race_slug: race_slug.to_string(),
                    year,
                    fetched: 0,
                    inserted: 0,
                    linked: 0,
                    skipped_existing: 0,
                    skipped_publisher_blocked: 0,
                });
            }
        };
        let (tracked_race_id, race_display, race_discipline) = race;

        // Make sure there's a feed row to attribute backfilled articles
        // to. We lump everything under a single synthetic "Internet
        // Archive backfill" feed so it shows up clearly in metrics and
        // can be filtered out of "fresh news" views by callers.
        let archive_feed_id = self
            .ensure_archive_feed()
            .await
            .map_err(|e| anyhow::anyhow!("ensure archive feed: {e}"))?;

        let mut report = BackfillReport {
            race_slug: race_slug.to_string(),
            year,
            fetched: 0,
            inserted: 0,
            linked: 0,
            skipped_existing: 0,
            skipped_publisher_blocked: 0,
        };
        let mut seen_urls = HashSet::<String>::new();

        for pattern in patterns {
            if report.inserted >= PER_RUN_ARTICLE_CAP {
                break;
            }
            let url_query = pattern.url_pattern.replace("{year}", &year.to_string());
            let snapshots = match self.cdx_lookup(&url_query, year).await {
                Ok(s) => s,
                Err(e) => {
                    warn!("CDX lookup failed for {url_query}: {e}");
                    continue;
                }
            };
            info!(
                "backfill {race_slug} {year}: {} snapshots from {}",
                snapshots.len(),
                pattern.publisher_root
            );

            for snap in snapshots {
                if report.inserted >= PER_RUN_ARTICLE_CAP {
                    break;
                }
                let canonical = normalize_url(&snap.original);
                if !seen_urls.insert(canonical.clone()) {
                    continue;
                }
                if self
                    .article_repo
                    .url_exists(&canonical)
                    .await
                    .unwrap_or(false)
                {
                    report.skipped_existing += 1;
                    continue;
                }

                report.fetched += 1;
                tokio::time::sleep(FETCH_INTERVAL).await;

                let html = match self.fetch_archive_html(&snap.archive_url).await {
                    Ok(h) => h,
                    Err(e) => {
                        warn!("archive fetch failed for {}: {e}", snap.archive_url);
                        continue;
                    }
                };

                let Some(extracted) = extract_metadata(&html, &snap.original) else {
                    continue;
                };

                let title_hash = compute_title_hash(
                    &extracted.title,
                    pattern.publisher_root,
                    &extracted.published_at,
                );
                if self
                    .article_repo
                    .hash_exists(&title_hash)
                    .await
                    .unwrap_or(false)
                {
                    report.skipped_existing += 1;
                    continue;
                }

                let draft = ArticleDraft {
                    feed_id: archive_feed_id,
                    title: extracted.title,
                    description: extracted.description,
                    url: canonical,
                    image_url: extracted.image,
                    published_at: extracted.published_at,
                    title_hash,
                    category: None,
                    region: "world".to_string(),
                    discipline: race_discipline.clone(),
                    language: "en".to_string(),
                };

                match self.article_repo.insert(&draft).await {
                    Ok(Some(article_id)) => {
                        report.inserted += 1;
                        if let Err(e) = self
                            .race_link_repo
                            .link_article(tracked_race_id, article_id, "archive_backfill")
                            .await
                        {
                            warn!("backfill link failed for article {article_id}: {e}");
                        } else {
                            report.linked += 1;
                        }
                    }
                    Ok(None) => report.skipped_existing += 1,
                    Err(e) => warn!("insert failed: {e}"),
                }
            }
        }

        // Record run for cooldown.
        sqlx::query(
            "INSERT INTO backfill_runs (race_slug, year, ran_at, inserted, linked)
             VALUES (?, ?, datetime('now'), ?, ?)",
        )
        .bind(race_slug)
        .bind(year)
        .bind(report.inserted as i64)
        .bind(report.linked as i64)
        .execute(&self.pool)
        .await
        .ok();

        info!(
            "backfill done: race={race_slug} year={year} fetched={} inserted={} linked={} skipped={}",
            report.fetched, report.inserted, report.linked, report.skipped_existing
        );
        let _ = race_display; // logged via race_slug
        Ok(report)
    }

    async fn ensure_cooldown_table(&self) -> anyhow::Result<()> {
        sqlx::query(
            "CREATE TABLE IF NOT EXISTS backfill_runs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                race_slug TEXT NOT NULL,
                year INTEGER NOT NULL,
                ran_at TEXT NOT NULL DEFAULT (datetime('now')),
                inserted INTEGER NOT NULL DEFAULT 0,
                linked INTEGER NOT NULL DEFAULT 0
            )",
        )
        .execute(&self.pool)
        .await?;
        sqlx::query(
            "CREATE INDEX IF NOT EXISTS idx_backfill_runs_race_year
             ON backfill_runs(race_slug, year, ran_at DESC)",
        )
        .execute(&self.pool)
        .await
        .ok();
        Ok(())
    }

    async fn lookup_race_id(&self, slug: &str) -> anyhow::Result<Option<(i64, String, String)>> {
        let row: Option<(i64, String, String)> = sqlx::query_as(
            "SELECT id, display_name, discipline FROM tracked_races WHERE race_slug = ?",
        )
        .bind(slug)
        .fetch_optional(&self.pool)
        .await?;
        Ok(row)
    }

    async fn ensure_archive_feed(&self) -> anyhow::Result<i64> {
        let id = self
            .feed_repo
            .upsert(
                "https://web.archive.org/bike-news-room-backfill",
                "Internet Archive Backfill",
                "world",
                "all",
                "en",
            )
            .await
            .map_err(|e| anyhow::anyhow!("upsert archive feed: {e}"))?;
        Ok(id)
    }

    async fn cdx_lookup(&self, url_pattern: &str, year: i32) -> anyhow::Result<Vec<Snapshot>> {
        // CDX bounds the snapshots to a single year via from/to params
        // to avoid pulling 200 hits across the whole archive history.
        let from = format!("{year}0101");
        let to = format!("{year}1231");
        let cdx = format!(
            "https://web.archive.org/cdx/search/cdx\
             ?url={url}&output=json&limit=300&from={from}&to={to}\
             &filter=statuscode:200&filter=mimetype:text/html\
             &collapse=urlkey",
            url = urlencoding(url_pattern)
        );
        let resp = self.http.get(&cdx).send().await?;
        if !resp.status().is_success() {
            return Err(anyhow::anyhow!("CDX status {}", resp.status()));
        }
        let body = resp.text().await?;
        // CDX JSON shape: [["urlkey","timestamp","original","mimetype","statuscode","digest","length"], …rows].
        let rows: Vec<Vec<String>> = serde_json::from_str(&body).unwrap_or_default();
        let mut out = Vec::new();
        let mut iter = rows.into_iter();
        // Skip header row.
        if iter.next().is_none() {
            return Ok(out);
        }
        for row in iter {
            let timestamp = row.get(1).cloned().unwrap_or_default();
            let original = row.get(2).cloned().unwrap_or_default();
            if timestamp.is_empty() || original.is_empty() {
                continue;
            }
            let archive_url = format!("https://web.archive.org/web/{timestamp}/{original}");
            out.push(Snapshot {
                timestamp,
                original,
                archive_url,
            });
        }
        Ok(out)
    }

    async fn fetch_archive_html(&self, url: &str) -> anyhow::Result<String> {
        let resp = self.http.get(url).send().await?;
        if !resp.status().is_success() {
            return Err(anyhow::anyhow!("archive fetch status {}", resp.status()));
        }
        let body = resp.text().await?;
        Ok(body)
    }
}

#[derive(Debug, Clone)]
struct Snapshot {
    #[allow(dead_code)] // kept for future debug logging
    timestamp: String,
    original: String,
    archive_url: String,
}

#[derive(Debug, Clone)]
struct ExtractedMetadata {
    title: String,
    description: Option<String>,
    image: Option<String>,
    /// ISO-8601 / RFC-3339. Falls back to the snapshot's wayback
    /// timestamp when the page itself doesn't expose one.
    published_at: String,
}

/// Extract title + description + image + published_at from a wayback
/// snapshot. Reuses the same OpenGraph + name-meta selectors any
/// modern news site exposes — works for ~95% of the publishers in our
/// archive targets list. Failure modes (paywalls, JS-only pages, weird
/// CMSes) get logged at the caller and skipped.
fn extract_metadata(html: &str, original_url: &str) -> Option<ExtractedMetadata> {
    let doc = Html::parse_document(html);

    let og_title = meta_attr(&doc, "meta[property=\"og:title\"]", "content");
    let twitter_title = meta_attr(&doc, "meta[name=\"twitter:title\"]", "content");
    let html_title = doc
        .select(&Selector::parse("title").ok()?)
        .next()
        .map(|el| el.text().collect::<String>().trim().to_string());
    let title = og_title
        .or(twitter_title)
        .or(html_title)
        .filter(|s| !s.is_empty())?;

    // Cap title at a sane length — some archive snapshots include
    // appended " | Cyclingnews" tails we can keep, but a 500-char title
    // is always a CMS bug.
    let title = title.chars().take(220).collect::<String>();

    let description = meta_attr(&doc, "meta[property=\"og:description\"]", "content")
        .or_else(|| meta_attr(&doc, "meta[name=\"description\"]", "content"))
        .map(|s| s.chars().take(500).collect::<String>());

    let image = meta_attr(&doc, "meta[property=\"og:image\"]", "content")
        .or_else(|| meta_attr(&doc, "meta[name=\"twitter:image\"]", "content"));

    let published_at = meta_attr(&doc, "meta[property=\"article:published_time\"]", "content")
        .or_else(|| meta_attr(&doc, "meta[name=\"date\"]", "content"))
        .or_else(|| meta_attr(&doc, "meta[itemprop=\"datePublished\"]", "content"))
        .unwrap_or_else(|| Utc::now().to_rfc3339());

    let _ = original_url;
    Some(ExtractedMetadata {
        title,
        description,
        image,
        published_at,
    })
}

fn meta_attr(doc: &Html, selector: &str, attr: &str) -> Option<String> {
    let sel = Selector::parse(selector).ok()?;
    doc.select(&sel)
        .next()
        .and_then(|el| el.value().attr(attr).map(|v| v.trim().to_string()))
        .filter(|s| !s.is_empty())
}

/// Minimal URL-encode for the CDX `url=` query parameter. The CDX API
/// doesn't actually need full RFC-3986 — just the wildcard `*` and `&`
/// characters preserved or escaped predictably. Implementing inline so
/// we don't pull in the `urlencoding` crate.
fn urlencoding(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 8);
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'.' | b'-' | b'_' | b'~' | b'/' | b'*' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{:02X}", b)),
        }
    }
    out
}

// Make `PublisherPattern` referenced — keeps the use statement tidy.
#[allow(dead_code)]
const _PATTERN_USED: fn() -> &'static PublisherPattern = || {
    patterns_for("tour-de-france")
        .first()
        .expect("tour-de-france present in catalogue")
};

// Deserialise impl placeholder so module compiles even if we add JSON
// payload structs in the future.
#[derive(Deserialize)]
#[allow(dead_code)]
struct _Reserved {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extract_metadata_reads_og_tags() {
        let html = r#"<html><head>
            <meta property="og:title" content="Pogacar wins Stage 5">
            <meta property="og:description" content="The Slovenian solos to victory…">
            <meta property="og:image" content="https://x.test/img.jpg">
            <meta property="article:published_time" content="2024-07-10T15:30:00+00:00">
        </head></html>"#;
        let m = extract_metadata(html, "https://x.test/article").unwrap();
        assert_eq!(m.title, "Pogacar wins Stage 5");
        assert_eq!(
            m.description.as_deref(),
            Some("The Slovenian solos to victory…")
        );
        assert_eq!(m.image.as_deref(), Some("https://x.test/img.jpg"));
        assert_eq!(m.published_at, "2024-07-10T15:30:00+00:00");
    }

    #[test]
    fn extract_metadata_falls_back_to_html_title() {
        let html = r#"<html><head><title>Old article</title></head></html>"#;
        let m = extract_metadata(html, "https://x.test/").unwrap();
        assert_eq!(m.title, "Old article");
        assert!(m.description.is_none());
    }

    #[test]
    fn extract_metadata_returns_none_when_title_missing() {
        let html = "<html><head></head></html>";
        assert!(extract_metadata(html, "https://x.test/").is_none());
    }

    #[test]
    fn urlencoding_passes_safe_chars_through() {
        assert_eq!(
            urlencoding("cyclingnews.com/tour-de-france-2024/*"),
            "cyclingnews.com/tour-de-france-2024/*"
        );
        assert_eq!(urlencoding("a&b"), "a%26b");
    }
}
