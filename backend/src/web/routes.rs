//! Axum router and handlers. All handlers delegate to use cases.

use std::sync::Arc;
use std::time::Instant;

use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use axum::routing::{get, post};
use axum::{Json, Router};

use sqlx::SqlitePool;

use crate::application::{
    AddSourceError, AddSourceRequest, AddUserSourceUseCase, BackfillArchiveUseCase, QueryUseCases,
    SourceKind,
};
use crate::domain::entities::{
    Article, ArticleQuery, FeedHealth, LiveTickerEntry, SourceCandidate,
};
use crate::domain::ports::{SourceCandidateRepository, SubscriberRepository};

use super::dto::*;
use super::errors::ApiError;

#[derive(Clone)]
pub struct AppState {
    pub queries: QueryUseCases,
    pub add_source: Arc<AddUserSourceUseCase>,
    pub candidates: Arc<dyn SourceCandidateRepository>,
    pub subscribers: Arc<dyn SubscriberRepository>,
    pub backfill: Arc<BackfillArchiveUseCase>,
    pub pool: SqlitePool,
    pub started_at: Instant,
}

pub fn create_router(
    queries: QueryUseCases,
    add_source: Arc<AddUserSourceUseCase>,
    candidates: Arc<dyn SourceCandidateRepository>,
    subscribers: Arc<dyn SubscriberRepository>,
    backfill: Arc<BackfillArchiveUseCase>,
    pool: SqlitePool,
) -> Router {
    let state = AppState {
        queries,
        add_source,
        candidates,
        subscribers,
        backfill,
        pool,
        started_at: Instant::now(),
    };

    Router::new()
        .route("/api/articles", get(list_articles))
        .route("/api/articles/{id}", get(get_article))
        .route("/api/articles/{id}/cluster", get(get_cluster))
        .route("/api/feeds", get(list_feeds))
        .route("/api/categories", get(list_categories))
        .route("/api/races", get(list_races))
        .route("/api/sources", post(register_source))
        .route("/api/sources/candidates", get(list_source_candidates))
        .route(
            "/api/admin/source-candidates/{id}/promote",
            post(promote_source_candidate),
        )
        .route(
            "/api/admin/source-candidates/{id}/reject",
            post(reject_source_candidate),
        )
        .route("/api/live-ticker", get(list_live_ticker))
        .route("/api/admin/live-ticker", post(post_live_ticker))
        .route("/api/admin/backfill", post(post_backfill))
        .route("/api/subscribers", post(subscribe))
        .route("/api/subscribers/confirm", get(confirm_subscriber))
        .route("/api/subscribers/unsubscribe", get(unsubscribe))
        .route("/api/health", get(health))
        .route("/api/metrics", get(metrics))
        // Public article landing — crawlers get OpenGraph HTML, humans
        // get a 302 to the SPA. Lives off /api so it's a clean public URL.
        .route("/article/{id}", get(super::article_html::article_landing))
        .route("/sitemap.xml", get(super::sitemap::sitemap_xml))
        .route("/robots.txt", get(super::sitemap::robots_txt))
        .with_state(state)
}

async fn list_articles(
    State(state): State<AppState>,
    Query(params): Query<ArticleQueryParams>,
) -> Result<Json<ArticlesResponse>, ApiError> {
    // Bound page so an attacker can't request `?page=99999999` and force a
    // huge OFFSET scan. 10k pages × 100/page = 1M articles is plenty.
    let page = params.page.unwrap_or(1).clamp(1, 10_000);
    let limit = params.limit.unwrap_or(20).clamp(1, 100);

    // `LIKE '%…%'` over a 10 KB string is expensive with no matching benefit.
    // Truncate at 100 chars and treat blank input as "no search".
    let search = params
        .search
        .map(|s| s.chars().take(100).collect::<String>())
        .filter(|s| !s.trim().is_empty());

    let query = ArticleQuery {
        page,
        limit,
        region: params.region,
        discipline: params.discipline,
        category: params.category,
        search,
        since: params.since,
        before: params.before,
        race_slug: params
            .race_slug
            .map(|s| s.chars().take(64).collect::<String>())
            .filter(|s| !s.trim().is_empty()),
    };

    let (articles, total) = state.queries.list_articles(&query).await?;
    let has_more = (page * limit) < total;

    Ok(Json(ArticlesResponse {
        articles,
        total,
        page,
        has_more,
    }))
}

async fn get_article(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Article>, StatusCode> {
    match state.queries.find_article(id).await {
        Ok(Some(a)) => Ok(Json(a)),
        Ok(None) => Err(StatusCode::NOT_FOUND),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

async fn get_cluster(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Vec<Article>>, ApiError> {
    let articles = state.queries.cluster_for(id).await?;
    Ok(Json(articles))
}

async fn list_feeds(State(state): State<AppState>) -> Result<Json<FeedsResponse>, ApiError> {
    let feeds = state.queries.list_feeds().await?;
    Ok(Json(FeedsResponse { feeds }))
}

async fn list_races(
    State(state): State<AppState>,
    Query(params): Query<RacesQueryParams>,
) -> Result<Json<RacesResponse>, ApiError> {
    let limit = params.limit.unwrap_or(40).clamp(1, 200);
    // Default `upcoming = true` preserves the existing calendar-page
    // contract — the page never sent the param before this change.
    let upcoming = params.upcoming.unwrap_or(true);
    let races = if upcoming {
        state
            .queries
            .upcoming_races(params.discipline.as_deref(), limit)
            .await?
    } else {
        state
            .queries
            .past_races(params.discipline.as_deref(), limit)
            .await?
    };
    Ok(Json(RacesResponse { races }))
}

async fn list_categories(
    State(state): State<AppState>,
) -> Result<Json<CategoriesResponse>, ApiError> {
    let categories = state.queries.category_counts().await?;
    Ok(Json(CategoriesResponse { categories }))
}

async fn health(State(state): State<AppState>) -> Result<Json<HealthResponse>, ApiError> {
    let article_count = state.queries.article_count().await.unwrap_or(0);
    let last_fetch = state.queries.last_fetch().await.unwrap_or(None);
    let uptime = state.started_at.elapsed().as_secs();

    Ok(Json(HealthResponse {
        status: "ok".to_string(),
        article_count,
        last_fetch,
        uptime_seconds: uptime,
    }))
}

async fn metrics(State(state): State<AppState>) -> Result<Json<MetricsResponse>, ApiError> {
    let article_count = state.queries.article_count().await?;
    let feeds = state.queries.list_feeds().await?;
    let categories = state.queries.category_counts().await?;
    let last_fetch = state.queries.last_fetch().await?;

    let mut healthy = 0;
    let mut degraded = 0;
    let mut disabled = 0;

    let feed_health: Vec<FeedHealthEntry> = feeds
        .iter()
        .map(|f| {
            let health = FeedHealth::from_error_count(f.error_count);
            let status = match health {
                FeedHealth::Healthy => {
                    healthy += 1;
                    "healthy"
                }
                FeedHealth::Degraded => {
                    degraded += 1;
                    "degraded"
                }
                FeedHealth::Disabled => {
                    disabled += 1;
                    "disabled"
                }
            };
            FeedHealthEntry {
                id: f.id,
                title: f.title.clone(),
                url: f.url.clone(),
                region: f.region.clone(),
                error_count: f.error_count,
                last_fetched_at: f.last_fetched_at.clone(),
                status,
            }
        })
        .collect();

    Ok(Json(MetricsResponse {
        article_count,
        feed_count: feeds.len(),
        healthy_feeds: healthy,
        degraded_feeds: degraded,
        disabled_feeds: disabled,
        last_fetch,
        uptime_seconds: state.started_at.elapsed().as_secs(),
        categories,
        feed_health,
    }))
}

/// User-submitted source registration.
///
/// Public endpoint. Rate-limited at the `tower_governor` layer to prevent
/// abuse; further hardened by the URL guard (rejects private IPs / non-http
/// schemes), payload-size cap, and a 15s probe timeout.
///
/// Returns 201 Created with the new feed_id + classification on success.
/// 400 / 422 for validation errors so the client can show a precise toast.
async fn register_source(
    State(state): State<AppState>,
    Json(body): Json<AddSourceBody>,
) -> Result<(StatusCode, Json<AddSourceResponseDto>), (StatusCode, Json<serde_json::Value>)> {
    let req = AddSourceRequest {
        url: body.url,
        name: body.name,
        region: body.region,
        discipline: body.discipline,
        language: body.language,
    };

    match state.add_source.execute(req).await {
        Ok(resp) => Ok((
            StatusCode::CREATED,
            Json(AddSourceResponseDto {
                feed_id: resp.feed_id,
                kind: match resp.kind {
                    SourceKind::Rss => "rss",
                    SourceKind::Crawl => "crawl",
                }
                .to_string(),
                title: resp.title,
                url: resp.url,
                sample_count: resp.sample_count,
            }),
        )),
        Err(e) => {
            // Map use-case errors to precise HTTP statuses.
            let status = match &e {
                AddSourceError::InvalidUrl(_) => StatusCode::BAD_REQUEST,
                AddSourceError::PayloadTooLarge => StatusCode::PAYLOAD_TOO_LARGE,
                AddSourceError::FetchFailed(_) => StatusCode::BAD_GATEWAY,
                AddSourceError::NoFeedFound => StatusCode::UNPROCESSABLE_ENTITY,
                AddSourceError::Repository(_) => {
                    tracing::error!("add_source repository error: {e}");
                    StatusCode::INTERNAL_SERVER_ERROR
                }
            };
            Err((
                status,
                Json(serde_json::json!({
                    "error": e.to_string(),
                })),
            ))
        }
    }
}

// ── Source-candidate (auto-growing source list) endpoints ──────────────────

#[derive(serde::Deserialize)]
struct CandidatesQuery {
    /// Hide noise — by default require at least 3 mentions to surface a domain.
    min_mentions: Option<i64>,
    limit: Option<i64>,
}

#[derive(serde::Serialize)]
struct CandidatesResponse {
    candidates: Vec<SourceCandidate>,
}

/// Public read of the discovered-domain queue. We expose this read-only so
/// curious users (and our own ops dashboard, eventually) can see what the
/// crawler is finding without needing the admin token.
async fn list_source_candidates(
    State(state): State<AppState>,
    Query(params): Query<CandidatesQuery>,
) -> Result<Json<CandidatesResponse>, ApiError> {
    let min_mentions = params.min_mentions.unwrap_or(3).clamp(1, 1000);
    let limit = params.limit.unwrap_or(50).clamp(1, 500);
    let candidates = state.candidates.list_pending(min_mentions, limit).await?;
    Ok(Json(CandidatesResponse { candidates }))
}

/// Admin auth — single shared secret in `ADMIN_TOKEN` env var. Anyone who
/// knows the value can promote/reject. We don't do per-user accounts because
/// the admin surface is one operator (us) for now.
fn require_admin(headers: &axum::http::HeaderMap) -> Result<(), StatusCode> {
    let expected = std::env::var("ADMIN_TOKEN").ok();
    let Some(expected) = expected.filter(|s| !s.is_empty()) else {
        // No token configured = admin endpoints are bolted shut. Safer than
        // accidentally leaving them open in production.
        return Err(StatusCode::FORBIDDEN);
    };
    let provided = headers
        .get("x-admin-token")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");
    if subtle_eq(provided.as_bytes(), expected.as_bytes()) {
        Ok(())
    } else {
        Err(StatusCode::FORBIDDEN)
    }
}

/// Constant-time byte compare so timing doesn't leak the token length.
fn subtle_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (x, y) in a.iter().zip(b.iter()) {
        diff |= x ^ y;
    }
    diff == 0
}

async fn promote_source_candidate(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
    Path(id): Path<i64>,
) -> Result<(StatusCode, Json<serde_json::Value>), (StatusCode, Json<serde_json::Value>)> {
    require_admin(&headers).map_err(|s| (s, Json(serde_json::json!({"error": "forbidden"}))))?;

    let candidate = match state.candidates.find(id).await {
        Ok(Some(c)) => c,
        Ok(None) => {
            return Err((
                StatusCode::NOT_FOUND,
                Json(serde_json::json!({"error": "candidate not found"})),
            ));
        }
        Err(_) => {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "lookup failed"})),
            ));
        }
    };

    if candidate.status != "pending" {
        return Err((
            StatusCode::CONFLICT,
            Json(serde_json::json!({
                "error": "candidate already adjudicated",
                "status": candidate.status,
            })),
        ));
    }

    let req = AddSourceRequest {
        url: candidate.sample_url.clone(),
        name: None,
        region: Some("world".to_string()),
        discipline: None,
        language: None,
    };

    match state.add_source.execute(req).await {
        Ok(resp) => {
            if let Err(e) = state.candidates.mark_approved(id, resp.feed_id).await {
                tracing::warn!("mark_approved failed: {e}");
            }
            Ok((
                StatusCode::OK,
                Json(serde_json::json!({
                    "status": "approved",
                    "feed_id": resp.feed_id,
                    "title": resp.title,
                    "url": resp.url,
                    "kind": match resp.kind {
                        SourceKind::Rss => "rss",
                        SourceKind::Crawl => "crawl",
                    },
                })),
            ))
        }
        Err(e) => Err((
            StatusCode::UNPROCESSABLE_ENTITY,
            Json(serde_json::json!({"error": e.to_string()})),
        )),
    }
}

async fn reject_source_candidate(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
    Path(id): Path<i64>,
) -> Result<StatusCode, (StatusCode, Json<serde_json::Value>)> {
    require_admin(&headers).map_err(|s| (s, Json(serde_json::json!({"error": "forbidden"}))))?;
    state.candidates.mark_rejected(id).await.map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": "reject failed"})),
        )
    })?;
    Ok(StatusCode::NO_CONTENT)
}

// ── Daily-digest subscription endpoints ────────────────────────────────────

#[derive(serde::Deserialize)]
struct SubscribeBody {
    email: String,
}

#[derive(serde::Deserialize)]
struct TokenQuery {
    token: String,
}

/// Lightweight email validator. Real validation happens when Resend tries to
/// deliver — here we just reject the obvious garbage so the table doesn't
/// fill up with junk like "asdf".
fn looks_like_email(s: &str) -> bool {
    let s = s.trim();
    if s.len() < 5 || s.len() > 254 {
        return false;
    }
    let at = s.find('@');
    let Some(at) = at else { return false };
    let (local, rest) = s.split_at(at);
    let domain = &rest[1..];
    !local.is_empty()
        && !domain.is_empty()
        && domain.contains('.')
        && !s.contains(' ')
        && !s.contains('\n')
}

/// Generate a 32-char hex token. Uses thread-local RNG via `rand`-free
/// approach: SHA-256 of (process_pid, monotonic_nanos, email, label).
/// Not cryptographically perfect, but the token only needs to be
/// unguessable by an attacker who doesn't know the email — and we have a
/// UNIQUE constraint that catches accidental collisions.
fn generate_token(email: &str, label: &str) -> String {
    use sha2::{Digest, Sha256};
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let pid = std::process::id();
    let mut h = Sha256::new();
    h.update(email.as_bytes());
    h.update(label.as_bytes());
    h.update(pid.to_be_bytes());
    h.update(now.to_be_bytes());
    let digest = h.finalize();
    hex::encode(&digest[..16])
}

async fn subscribe(
    State(state): State<AppState>,
    Json(body): Json<SubscribeBody>,
) -> Result<(StatusCode, Json<serde_json::Value>), (StatusCode, Json<serde_json::Value>)> {
    let email = body.email.trim().to_lowercase();
    if !looks_like_email(&email) {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({"error": "invalid email"})),
        ));
    }
    let confirm = generate_token(&email, "confirm");
    let unsub = generate_token(&email, "unsub");

    let sub = state
        .subscribers
        .upsert_pending(&email, &confirm, &unsub)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "save failed"})),
            )
        })?;

    // Don't reveal whether the address was already subscribed — that would be
    // an enumeration oracle. Always return the same shape.
    Ok((
        StatusCode::ACCEPTED,
        Json(serde_json::json!({
            "status": sub.status,
            "message": "If the address is valid, a confirmation email is on its way.",
        })),
    ))
}

async fn confirm_subscriber(
    State(state): State<AppState>,
    Query(q): Query<TokenQuery>,
) -> Result<axum::response::Html<String>, StatusCode> {
    let Some(sub) = state
        .subscribers
        .find_by_confirm_token(&q.token)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    else {
        return Err(StatusCode::NOT_FOUND);
    };
    state
        .subscribers
        .mark_confirmed(sub.id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(axum::response::Html(
        "<!doctype html><meta charset=utf-8><title>Confirmed</title>\
         <body style=\"font-family:Georgia,serif;max-width:520px;margin:60px auto;padding:24px;text-align:center\">\
         <h1>You're in.</h1><p>The next Bike News Room digest will land in your inbox tomorrow morning.</p>\
         <p><a href=\"https://bike-news-room.pages.dev/\">Back to the wire →</a></p>"
            .to_string(),
    ))
}

async fn unsubscribe(
    State(state): State<AppState>,
    Query(q): Query<TokenQuery>,
) -> Result<axum::response::Html<String>, StatusCode> {
    let Some(sub) = state
        .subscribers
        .find_by_unsubscribe_token(&q.token)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    else {
        return Err(StatusCode::NOT_FOUND);
    };
    state
        .subscribers
        .mark_unsubscribed(sub.id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(axum::response::Html(
        "<!doctype html><meta charset=utf-8><title>Unsubscribed</title>\
         <body style=\"font-family:Georgia,serif;max-width:520px;margin:60px auto;padding:24px;text-align:center\">\
         <h1>You're out.</h1><p>You'll no longer receive Bike News Room digests.</p>"
            .to_string(),
    ))
}

// ── Live race ticker endpoints ─────────────────────────────────────────────

#[derive(serde::Deserialize)]
struct LiveTickerQuery {
    /// Window in hours; defaults to 6 (a typical race-stage length).
    hours: Option<i64>,
    limit: Option<i64>,
}

#[derive(serde::Serialize)]
struct LiveTickerResponse {
    entries: Vec<LiveTickerEntry>,
}

async fn list_live_ticker(
    State(state): State<AppState>,
    Query(q): Query<LiveTickerQuery>,
) -> Result<Json<LiveTickerResponse>, ApiError> {
    let hours = q.hours.unwrap_or(6).clamp(1, 48);
    let limit = q.limit.unwrap_or(20).clamp(1, 100);
    // SQLite's datetime() supports relative arithmetic — keep the cutoff
    // logic in the query so we don't have to format times client-side.
    let cutoff = format!("-{hours} hours");
    let rows = sqlx::query_as::<_, LiveTickerEntry>(
        "SELECT id, race_name, headline, kind, source_url, posted_at
         FROM live_ticker_entries
         WHERE posted_at >= datetime('now', ?)
         ORDER BY posted_at DESC
         LIMIT ?",
    )
    .bind(&cutoff)
    .bind(limit)
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("live-ticker list failed: {e}");
        ApiError(crate::domain::errors::DomainError::Repository(
            e.to_string(),
        ))
    })?;
    Ok(Json(LiveTickerResponse { entries: rows }))
}

#[derive(serde::Deserialize)]
struct LiveTickerBody {
    race_name: String,
    headline: String,
    kind: Option<String>,
    source_url: Option<String>,
}

/// Admin-only — push a single live-ticker entry. Used for now as the
/// primary insertion path until the PCS scraper is wired in.
async fn post_live_ticker(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
    Json(body): Json<LiveTickerBody>,
) -> Result<(StatusCode, Json<serde_json::Value>), (StatusCode, Json<serde_json::Value>)> {
    require_admin(&headers).map_err(|s| (s, Json(serde_json::json!({"error": "forbidden"}))))?;

    let race_name = body.race_name.trim();
    let headline = body.headline.trim();
    if race_name.is_empty() || headline.is_empty() || race_name.len() > 80 || headline.len() > 280 {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(
                serde_json::json!({"error": "race_name and headline required (race_name ≤80, headline ≤280)"}),
            ),
        ));
    }
    let kind = body
        .kind
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("update");

    let id: i64 = sqlx::query_scalar(
        "INSERT INTO live_ticker_entries (race_name, headline, kind, source_url)
         VALUES (?, ?, ?, ?) RETURNING id",
    )
    .bind(race_name)
    .bind(headline)
    .bind(kind)
    .bind(body.source_url.as_deref())
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("live-ticker insert failed: {e}");
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(serde_json::json!({"error": "insert failed"})),
        )
    })?;

    Ok((StatusCode::CREATED, Json(serde_json::json!({"id": id}))))
}

#[derive(serde::Deserialize)]
struct BackfillBody {
    /// Race slug from the matcher catalogue, e.g. "tour-de-france".
    race_slug: String,
    /// Number of years back to scan from the current calendar year.
    /// Default 3 — covers the typical "last few editions" expectation.
    years: Option<i32>,
    /// Skip the 30-day cooldown when set. Used after a publisher
    /// restructures their archive URLs and we want to re-scan.
    force: Option<bool>,
}

#[derive(serde::Serialize)]
struct BackfillResponseDto {
    race_slug: String,
    runs: Vec<BackfillRunDto>,
    total_inserted: usize,
    total_linked: usize,
}

#[derive(serde::Serialize)]
struct BackfillRunDto {
    year: i32,
    fetched: usize,
    inserted: usize,
    linked: usize,
    skipped_existing: usize,
}

/// Admin-only Internet Archive backfill trigger.
///
/// `POST /api/admin/backfill` body: `{ "race_slug": "tour-de-france", "years": 3 }`
/// Runs the backfill use case once per (race, year) within the
/// requested range. Each year is rate-limited at 1 req/2s per publisher,
/// so a 3-year run for a Grand Tour with 4 publishers takes ~5 min in
/// the worst case. The endpoint blocks until done — admins watch the
/// terminal logs while it runs.
async fn post_backfill(
    State(state): State<AppState>,
    headers: axum::http::HeaderMap,
    Json(body): Json<BackfillBody>,
) -> Result<(StatusCode, Json<BackfillResponseDto>), (StatusCode, Json<serde_json::Value>)> {
    require_admin(&headers).map_err(|s| (s, Json(serde_json::json!({"error": "forbidden"}))))?;

    let years = body.years.unwrap_or(3).clamp(1, 10);
    let force = body.force.unwrap_or(false);
    let current_year = chrono::Utc::now()
        .format("%Y")
        .to_string()
        .parse::<i32>()
        .unwrap_or(2026);

    let mut total_inserted = 0usize;
    let mut total_linked = 0usize;
    let mut runs = Vec::with_capacity(years as usize);

    // Iterate from oldest -> newest so partial-failure runs leave the
    // most-recent year for last (the year users care about most).
    for offset in (0..years).rev() {
        let year = current_year - offset;
        match state.backfill.run(&body.race_slug, year, force).await {
            Ok(report) => {
                total_inserted += report.inserted;
                total_linked += report.linked;
                runs.push(BackfillRunDto {
                    year: report.year,
                    fetched: report.fetched,
                    inserted: report.inserted,
                    linked: report.linked,
                    skipped_existing: report.skipped_existing,
                });
            }
            Err(e) => {
                tracing::error!("backfill year {year} failed: {e}");
                runs.push(BackfillRunDto {
                    year,
                    fetched: 0,
                    inserted: 0,
                    linked: 0,
                    skipped_existing: 0,
                });
            }
        }
    }

    Ok((
        StatusCode::OK,
        Json(BackfillResponseDto {
            race_slug: body.race_slug,
            runs,
            total_inserted,
            total_linked,
        }),
    ))
}
