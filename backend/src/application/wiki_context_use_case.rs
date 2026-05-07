//! Wikipedia context lookup — fetches a short summary + thumbnail for
//! a given entity (rider, team, race) from the Wikipedia REST API.
//!
//! Why this exists: the existing rider/team/race detail pages show
//! the entity name + the article list we've matched to it. Adding a
//! one-paragraph context block ("Tadej Pogačar is a Slovenian road
//! cyclist born in 1998 who races for UAE Team Emirates…") with the
//! Wikipedia thumbnail gives users an instant sanity check that
//! they're looking at the right person, without having to leave the
//! app.
//!
//! Free + no auth — Wikipedia REST API is public and unrestricted up
//! to ~200 req/s per IP. We cache the JSON body in a SQLite table for
//! 7 days so repeat opens of the same entity don't hammer Wikipedia.
//!
//! Localisation: we ask the user's locale via the `lang` param
//! (`en`, `pl`, `es`, …); Wikipedia respects locale-specific summaries
//! out of the box. Falls back to `en` when the requested locale has
//! no article for the entity.

use std::time::Duration;

use chrono::Utc;
use serde::{Deserialize, Serialize};
use sqlx::SqlitePool;
use tracing::warn;

use crate::domain::errors::DomainResult;

/// Cache TTL for Wikipedia summaries. 7 days because rider info
/// (current team, age) changes only on transfer windows / birthdays.
const CACHE_TTL_DAYS: i64 = 7;

#[derive(Debug, Clone, Serialize)]
pub struct WikiContext {
    /// The entity title as Wikipedia knows it (may differ from our
    /// catalogue id — e.g. our "tour-de-france" vs Wikipedia's
    /// "Tour de France").
    pub title: String,
    /// One-paragraph plain-text summary. Wikipedia caps these to ~120
    /// words; we forward as-is.
    pub extract: String,
    /// Wikipedia REST URL for the full article — drives a "Read more
    /// on Wikipedia" CTA in the UI.
    pub source_url: String,
    /// Thumbnail image URL when Wikipedia has one, else `None`. The
    /// frontend already gracefully handles missing images.
    pub thumbnail_url: Option<String>,
    /// Locale Wikipedia served the summary in. Useful for
    /// debugging fall-back paths.
    pub lang: String,
    /// `true` when served from our SQLite cache; `false` when we just
    /// hit Wikipedia. Dev/ops signal only.
    pub from_cache: bool,
}

#[derive(Clone)]
pub struct WikiContextUseCase {
    pool: SqlitePool,
    client: reqwest::Client,
}

impl WikiContextUseCase {
    pub fn new(pool: SqlitePool) -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(10))
            .user_agent(
                "BikeNewsRoom/1.3 (+https://bike-news-room.pages.dev/about; \
                 contact@bike-news-room)",
            )
            .build()
            .expect("build reqwest client");
        Self { pool, client }
    }

    /// Idempotent. Returns `Ok(None)` when Wikipedia has no article for
    /// the given title in any of the requested + fallback locales.
    pub async fn execute(&self, title: &str, lang: &str) -> DomainResult<Option<WikiContext>> {
        if let Some(cached) = self.read_cache(title, lang).await? {
            return Ok(Some(cached));
        }
        // Try requested locale first, then English fallback.
        for try_lang in [lang, "en"] {
            if let Some(ctx) = self.fetch(title, try_lang).await {
                self.write_cache(&ctx).await?;
                return Ok(Some(ctx));
            }
        }
        Ok(None)
    }

    async fn fetch(&self, title: &str, lang: &str) -> Option<WikiContext> {
        // The REST `summary` endpoint takes a URL-encoded title. Spaces
        // are converted to underscores per Wikipedia convention.
        let path = title.replace(' ', "_");
        let encoded = urlencoding::encode(&path);
        let url = format!("https://{lang}.wikipedia.org/api/rest_v1/page/summary/{encoded}",);
        let res = match self.client.get(&url).send().await {
            Ok(r) => r,
            Err(e) => {
                warn!("wiki_context: fetch failed for {title} ({lang}): {e}");
                return None;
            }
        };
        if !res.status().is_success() {
            return None;
        }
        let body: WikiSummary = match res.json().await {
            Ok(b) => b,
            Err(e) => {
                warn!("wiki_context: parse failed for {title} ({lang}): {e}");
                return None;
            }
        };
        // Wikipedia returns disambiguation pages and redirects with the
        // same shape as articles; treat empty extract as "nothing useful".
        let extract = body.extract.unwrap_or_default();
        if extract.trim().is_empty() {
            return None;
        }
        Some(WikiContext {
            title: body.title.unwrap_or_else(|| title.to_string()),
            extract,
            source_url: body
                .content_urls
                .as_ref()
                .map(|u| u.desktop.page.clone())
                .unwrap_or_else(|| format!("https://{lang}.wikipedia.org/wiki/{path}")),
            thumbnail_url: body.thumbnail.as_ref().map(|t| t.source.clone()),
            lang: lang.to_string(),
            from_cache: false,
        })
    }

    async fn read_cache(&self, title: &str, lang: &str) -> DomainResult<Option<WikiContext>> {
        let row = sqlx::query_as::<_, (String, String, String, Option<String>, String, String)>(
            "SELECT title, extract, source_url, thumbnail_url, lang, fetched_at
             FROM wiki_context
             WHERE cache_key = ?",
        )
        .bind(format!("{title}|{lang}"))
        .fetch_optional(&self.pool)
        .await?;
        let Some((t, extract, src, thumb, l, fetched_at)) = row else {
            return Ok(None);
        };
        if let Ok(parsed) = chrono::DateTime::parse_from_rfc3339(&fetched_at) {
            if Utc::now() - parsed.with_timezone(&Utc) > chrono::Duration::days(CACHE_TTL_DAYS) {
                return Ok(None);
            }
        }
        Ok(Some(WikiContext {
            title: t,
            extract,
            source_url: src,
            thumbnail_url: thumb,
            lang: l,
            from_cache: true,
        }))
    }

    async fn write_cache(&self, ctx: &WikiContext) -> DomainResult<()> {
        let now = Utc::now().to_rfc3339();
        // Keyed by "<original-title>|<lang>" so identical titles in
        // different locales cache independently. Upsert so a stale row
        // gets overwritten on next miss-then-fetch.
        sqlx::query(
            "INSERT INTO wiki_context
              (cache_key, title, extract, source_url, thumbnail_url, lang, fetched_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(cache_key) DO UPDATE SET
              title=excluded.title,
              extract=excluded.extract,
              source_url=excluded.source_url,
              thumbnail_url=excluded.thumbnail_url,
              lang=excluded.lang,
              fetched_at=excluded.fetched_at",
        )
        .bind(format!("{}|{}", ctx.title, ctx.lang))
        .bind(&ctx.title)
        .bind(&ctx.extract)
        .bind(&ctx.source_url)
        .bind(&ctx.thumbnail_url)
        .bind(&ctx.lang)
        .bind(&now)
        .execute(&self.pool)
        .await?;
        Ok(())
    }
}

// ── Wikipedia REST response shape ───────────────────────────────────
// Only the fields we actually use are deserialised; the API returns ~25
// fields per summary (page id, namespace, type, etc) we don't need.

#[derive(Debug, Deserialize)]
struct WikiSummary {
    title: Option<String>,
    extract: Option<String>,
    content_urls: Option<WikiContentUrls>,
    thumbnail: Option<WikiThumb>,
}

#[derive(Debug, Deserialize)]
struct WikiContentUrls {
    desktop: WikiUrls,
}

#[derive(Debug, Deserialize)]
struct WikiUrls {
    page: String,
}

#[derive(Debug, Deserialize)]
struct WikiThumb {
    source: String,
}
