//! Axum router and handlers. All handlers delegate to use cases.

use std::sync::Arc;
use std::time::Instant;

use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use axum::routing::{get, post};
use axum::{Json, Router};

use crate::application::{
    AddSourceError, AddSourceRequest, AddUserSourceUseCase, QueryUseCases, SourceKind,
};
use crate::domain::entities::{Article, ArticleQuery, FeedHealth};

use super::dto::*;
use super::errors::ApiError;

#[derive(Clone)]
pub struct AppState {
    pub queries: QueryUseCases,
    pub add_source: Arc<AddUserSourceUseCase>,
    pub started_at: Instant,
}

pub fn create_router(
    queries: QueryUseCases,
    add_source: Arc<AddUserSourceUseCase>,
) -> Router {
    let state = AppState {
        queries,
        add_source,
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
        .route("/api/health", get(health))
        .route("/api/metrics", get(metrics))
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
    let races = state
        .queries
        .upcoming_races(params.discipline.as_deref(), limit)
        .await?;
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
