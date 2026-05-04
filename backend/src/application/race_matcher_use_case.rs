//! Article ↔ race tagging at ingest time + one-shot retro-scan.
//!
//! Workflow:
//!   1. At startup, [`RaceMatcherUseCase::seed_from_catalogue`] reads
//!      `data/cycling_races.json`, upserts each race into `tracked_races`
//!      (idempotent), and builds an in-memory [`RaceCatalogue`] of
//!      pre-normalised aliases for fast matching.
//!   2. Every successful article insert in [`crate::application::IngestFeedsUseCase`]
//!      calls [`RaceMatcherUseCase::match_and_link`], which scans the
//!      title + description against the catalogue and inserts hits into
//!      `race_articles`.
//!   3. On first deploy after this code lands, [`RaceMatcherUseCase::retro_scan`]
//!      sweeps every existing article published in the retention window
//!      and applies the matcher retroactively, so the historic inventory
//!      is linked + retention-exempted before the next sweep.

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use serde::Deserialize;
use sqlx::SqlitePool;
use tokio::sync::RwLock;
use tracing::{info, warn};

use crate::domain::ports::RaceLinkRepository;
use crate::domain::services::race_matcher::{
    normalise as normalise_for_match, RaceCatalogue, RaceMatchEntry,
};

/// Quality knobs applied at catalogue load time. Matches the design
/// note in the planning doc: short, ambiguous aliases ("Giro" alone)
/// would tag too many unrelated articles, so they're filtered out of
/// the auto-tagger. The frontend search keeps them — user-typed search
/// is intentional, auto-tagging is not.
const MIN_SINGLE_TOKEN_ALIAS_LEN: usize = 8;

#[derive(Debug, Deserialize)]
struct CatalogueFile {
    races: Vec<CatalogueRaceEntry>,
}

#[derive(Debug, Deserialize)]
struct CatalogueRaceEntry {
    id: String,
    name: String,
    discipline: String,
    #[serde(default)]
    strong_aliases: Vec<String>,
    #[serde(default)]
    weak_aliases: Vec<String>,
}

pub struct RaceMatcherUseCase {
    repo: Arc<dyn RaceLinkRepository>,
    pool: SqlitePool,
    /// (race_slug → tracked_races.id). Filled at seed time so the
    /// matcher hot path is O(1) lookup, not a SQL roundtrip per article.
    slug_to_id: RwLock<HashMap<String, i64>>,
    catalogue: RwLock<RaceCatalogue>,
}

impl RaceMatcherUseCase {
    pub fn new(repo: Arc<dyn RaceLinkRepository>, pool: SqlitePool) -> Self {
        Self {
            repo,
            pool,
            slug_to_id: RwLock::new(HashMap::new()),
            catalogue: RwLock::new(RaceCatalogue::default()),
        }
    }

    /// Read the catalogue JSON, upsert into `tracked_races`, build the
    /// in-memory matcher. Call once at startup. Subsequent calls reload
    /// the catalogue idempotently — useful if you mount the JSON as a
    /// volume and want to refresh without restarting.
    pub async fn seed_from_catalogue(&self, path: &PathBuf) -> anyhow::Result<()> {
        let raw = match std::fs::read_to_string(path) {
            Ok(s) => s,
            Err(e) => {
                warn!(
                    "race catalogue at {} unreadable, skipping seed: {e}",
                    path.display()
                );
                return Ok(());
            }
        };
        let parsed: CatalogueFile = serde_json::from_str(&raw)?;

        let mut entries = Vec::with_capacity(parsed.races.len());
        let mut slug_to_id = HashMap::with_capacity(parsed.races.len());

        for race in parsed.races {
            // Persist (or refresh) the brand row.
            let id = self
                .repo
                .upsert_tracked_race(&race.id, &race.name, &race.discipline)
                .await
                .map_err(|e| anyhow::anyhow!("upsert tracked_race {}: {e}", race.id))?;
            slug_to_id.insert(race.id.clone(), id);

            // Apply quality rules: drop aliases that are too short and
            // single-token (would noise-tag everything mentioning the
            // word "Giro" or "Tour"). Multi-token aliases are kept
            // even when individually short, since "Tour de France" is
            // unambiguous as a phrase.
            let mut normalised_aliases = Vec::new();
            for alias in race
                .strong_aliases
                .iter()
                .chain(race.weak_aliases.iter().filter(|a| {
                    let tokens = a.split_whitespace().count();
                    tokens >= 2 || a.chars().count() >= MIN_SINGLE_TOKEN_ALIAS_LEN
                }))
            {
                let normalised = normalise_for_match(alias);
                if normalised.trim().is_empty() {
                    continue;
                }
                if !normalised_aliases.contains(&normalised) {
                    normalised_aliases.push(normalised);
                }
            }

            if normalised_aliases.is_empty() {
                warn!(
                    "race {} has no usable aliases after quality filter, skipping from matcher",
                    race.id
                );
                continue;
            }

            entries.push(RaceMatchEntry {
                race_id: race.id.clone(),
                display_name: race.name.clone(),
                discipline: race.discipline.clone(),
                normalised_aliases,
            });
        }

        let entry_count = entries.len();
        let mut cat = self.catalogue.write().await;
        cat.entries = entries;
        let mut map = self.slug_to_id.write().await;
        *map = slug_to_id;

        info!("race matcher seeded with {} races", entry_count);
        Ok(())
    }

    /// Match a single newly-inserted article against the catalogue and
    /// persist links. Called from the ingest hook. Failures are logged
    /// and swallowed — race tagging is best-effort and shouldn't block
    /// article ingestion.
    pub async fn match_and_link(
        &self,
        article_id: i64,
        title: &str,
        description: Option<&str>,
        article_discipline: Option<&str>,
    ) {
        let cat = self.catalogue.read().await;
        if cat.entries.is_empty() {
            return;
        }
        let hits = cat.match_article(title, description, article_discipline);
        drop(cat);
        if hits.is_empty() {
            return;
        }

        let map = self.slug_to_id.read().await;
        for hit in hits {
            let Some(&race_id) = map.get(&hit.race_id) else {
                continue;
            };
            if let Err(e) = self
                .repo
                .link_article(race_id, article_id, &hit.matched_alias)
                .await
            {
                warn!(
                    "race-link insert failed (race={}, article={}): {e}",
                    hit.race_id, article_id
                );
            }
        }
    }

    /// One-shot retroactive scan over the existing article inventory.
    /// Idempotent — the link table's PRIMARY KEY ignores duplicates.
    /// Call once per deploy after `seed_from_catalogue` so historic
    /// articles get tagged + retention-exempted before the next sweep.
    ///
    /// Scope: articles published within the last `lookback_days` days,
    /// excluding duplicates. Default 365 — anything older has already
    /// been swept by previous retention runs.
    pub async fn retro_scan(&self, lookback_days: i64) -> anyhow::Result<u64> {
        let cutoff = format!("-{lookback_days} days");

        // Stream rows in batches so we don't pull 50k articles into
        // memory on a populous DB.
        const BATCH: i64 = 500;
        let mut linked = 0u64;
        let mut last_id: i64 = 0;

        loop {
            let rows: Vec<(i64, String, Option<String>, Option<String>)> = sqlx::query_as(
                "SELECT id, title, description, discipline
                 FROM articles
                 WHERE published_at > datetime('now', ?)
                   AND id > ?
                   AND is_duplicate = 0
                 ORDER BY id ASC
                 LIMIT ?",
            )
            .bind(&cutoff)
            .bind(last_id)
            .bind(BATCH)
            .fetch_all(&self.pool)
            .await?;

            if rows.is_empty() {
                break;
            }

            for (id, title, description, discipline) in &rows {
                let cat = self.catalogue.read().await;
                let hits = cat.match_article(title, description.as_deref(), discipline.as_deref());
                drop(cat);

                if hits.is_empty() {
                    continue;
                }

                let map = self.slug_to_id.read().await;
                for hit in hits {
                    let Some(&race_id) = map.get(&hit.race_id) else {
                        continue;
                    };
                    if let Err(e) = self
                        .repo
                        .link_article(race_id, *id, &hit.matched_alias)
                        .await
                    {
                        warn!(
                            "retro-scan link failed (race={}, article={id}): {e}",
                            hit.race_id
                        );
                        continue;
                    }
                    linked += 1;
                }
            }

            last_id = rows.last().map(|(id, _, _, _)| *id).unwrap_or(last_id);
            if (rows.len() as i64) < BATCH {
                break;
            }
        }

        info!("retro-scan complete: {linked} race links created");
        Ok(linked)
    }
}
