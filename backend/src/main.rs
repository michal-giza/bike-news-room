use std::path::PathBuf;
use std::sync::Arc;

use sqlx::sqlite::SqlitePoolOptions;
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::{error, info};
use tracing_subscriber::EnvFilter;

use bike_news_room::application::{
    CrawlSitesUseCase, IngestFeedsUseCase, QueryUseCases, SyncCalendarUseCase,
};
use bike_news_room::domain::ports::{ArticleRepository, FeedRepository, RaceRepository};
use bike_news_room::infrastructure::{
    init_schema, snapshot, spawn_periodic_snapshot, AppConfig, ReqwestRssFetcher,
    ScraperHtmlCrawler, SnapshotConfig, SqliteRepository,
};
use bike_news_room::web::{crawl_targets::default_targets, create_router};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let log_filter = EnvFilter::from_default_env().add_directive("bike_news_room=info".parse()?);
    if std::env::var("LOG_FORMAT").as_deref() == Ok("json") {
        tracing_subscriber::fmt()
            .with_env_filter(log_filter)
            .json()
            .with_current_span(true)
            .init();
    } else {
        tracing_subscriber::fmt().with_env_filter(log_filter).init();
    }

    // ── Configuration ────────────────────────────────────────────────────
    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite://bike_news.db?mode=rwc".to_string());
    let feeds_path = std::env::var("FEEDS_PATH").unwrap_or_else(|_| "feeds.toml".to_string());
    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(7860);

    let app_config = AppConfig::load(&PathBuf::from(&feeds_path))?;
    info!("loaded {} RSS feed sources", app_config.feeds.len());

    let crawl_targets = default_targets();
    info!("loaded {} crawl targets", crawl_targets.len());

    // ── Snapshot restore (optional) ─────────────────────────────────────
    let snapshot_config = SnapshotConfig::from_env();
    if let Some(ref cfg) = snapshot_config {
        if let Some(db_path) = sqlite_path_from_url(&db_url) {
            // Strip query string before logging — presigned-URL credentials
            // sometimes live there (e.g. S3 SigV4) and shouldn't hit logs.
            let safe_log = url::Url::parse(&cfg.url)
                .map(|mut u| {
                    u.set_query(None);
                    u.to_string()
                })
                .unwrap_or_else(|_| "<malformed snapshot URL>".to_string());
            info!("snapshot: attempting restore from {safe_log}");
            snapshot::restore_if_configured(&db_path, cfg).await;
        }
    }

    // ── Infrastructure ───────────────────────────────────────────────────
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await?;
    init_schema(&pool).await?;
    info!("database initialized");

    // ── Spawn periodic snapshot uploader (if configured) ────────────────
    if let Some(cfg) = snapshot_config {
        if let Some(db_path) = sqlite_path_from_url(&db_url) {
            info!(
                "snapshot: enabling periodic upload every {:?}",
                cfg.interval
            );
            spawn_periodic_snapshot(db_path, cfg);
        }
    }

    let repository = Arc::new(SqliteRepository::new(pool));
    let article_repo: Arc<dyn ArticleRepository> = repository.clone();
    let feed_repo: Arc<dyn FeedRepository> = repository.clone();
    let race_repo: Arc<dyn RaceRepository> = repository.clone();

    let rss_fetcher = Arc::new(ReqwestRssFetcher::new());
    let html_crawler = Arc::new(ScraperHtmlCrawler::new());

    // ── Application (use cases) ──────────────────────────────────────────
    let ingest_uc = Arc::new(IngestFeedsUseCase::new(
        rss_fetcher,
        article_repo.clone(),
        feed_repo.clone(),
    ));
    let crawl_uc = Arc::new(CrawlSitesUseCase::new(
        html_crawler,
        article_repo.clone(),
        feed_repo.clone(),
    ));
    let calendar_uc = Arc::new(SyncCalendarUseCase::new(race_repo.clone()));
    let query_uc = QueryUseCases::new(article_repo, feed_repo, race_repo);

    // ── Initial fetch on startup ────────────────────────────────────────
    let startup_ingest = ingest_uc.clone();
    let startup_crawl = crawl_uc.clone();
    let startup_calendar = calendar_uc.clone();
    let startup_feeds = app_config.feeds.clone();
    let startup_targets = crawl_targets.clone();
    tokio::spawn(async move {
        info!("running initial RSS fetch...");
        startup_ingest.execute(&startup_feeds).await;
        info!("running initial crawl...");
        startup_crawl.execute(&startup_targets).await;
        info!("running initial race-calendar sync...");
        startup_calendar.execute().await;
        info!("initial ingestion complete");
    });

    // ── Scheduled fetches every 30 minutes ──────────────────────────────
    let scheduler = JobScheduler::new().await?;
    let sched_ingest = ingest_uc.clone();
    let sched_crawl = crawl_uc.clone();
    let sched_feeds = app_config.feeds.clone();
    let sched_targets = crawl_targets.clone();

    scheduler
        .add(Job::new_async("0 */30 * * * *", move |_, _| {
            let ingest = sched_ingest.clone();
            let crawl = sched_crawl.clone();
            let feeds = sched_feeds.clone();
            let targets = sched_targets.clone();
            Box::pin(async move {
                info!("scheduled fetch starting...");
                ingest.execute(&feeds).await;
                crawl.execute(&targets).await;
                info!("scheduled fetch complete");
            })
        })?)
        .await?;

    // Calendar sync runs daily at 03:00 — race schedules don't change minute-to-minute.
    let daily_calendar = calendar_uc.clone();
    scheduler
        .add(Job::new_async("0 0 3 * * *", move |_, _| {
            let cal = daily_calendar.clone();
            Box::pin(async move {
                info!("daily calendar sync starting...");
                cal.execute().await;
                info!("daily calendar sync complete");
            })
        })?)
        .await?;

    scheduler.start().await?;
    info!("scheduler started (RSS+crawl every 30m, calendar 03:00 daily)");

    // ── HTTP server ──────────────────────────────────────────────────────
    let cors = build_cors_layer();

    // Rate limit: per-IP sliding window. Defaults are generous for a public read API.
    let governor_conf = std::sync::Arc::new(
        tower_governor::governor::GovernorConfigBuilder::default()
            .per_second(10)
            .burst_size(50)
            .finish()
            .ok_or_else(|| anyhow::anyhow!("governor config invalid"))?,
    );
    let governor_layer = tower_governor::GovernorLayer {
        config: governor_conf,
    };

    // Baseline security headers — JSON API only, so the strictest CSP applies.
    use tower_http::set_header::SetResponseHeaderLayer;
    let header_layers = tower::ServiceBuilder::new()
        .layer(SetResponseHeaderLayer::if_not_present(
            axum::http::header::HeaderName::from_static("x-content-type-options"),
            axum::http::HeaderValue::from_static("nosniff"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            axum::http::header::HeaderName::from_static("x-frame-options"),
            axum::http::HeaderValue::from_static("DENY"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            axum::http::header::HeaderName::from_static("referrer-policy"),
            axum::http::HeaderValue::from_static("no-referrer"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            axum::http::header::HeaderName::from_static("content-security-policy"),
            axum::http::HeaderValue::from_static(
                "default-src 'none'; frame-ancestors 'none'",
            ),
        ));

    let app = create_router(query_uc)
        .layer(cors)
        .layer(header_layers)
        .layer(governor_layer);

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}")).await?;
    info!("server listening on port {port}");

    // `into_make_service_with_connect_info::<SocketAddr>()` is required so the
    // governor key-extractor can read the client IP. Without it, every
    // request fails with "Unable To Extract Key!".
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<std::net::SocketAddr>(),
    )
    .await
    .map_err(|e| {
        error!("server error: {e}");
        anyhow::anyhow!("server error: {e}")
    })
}

/// Build the CORS layer.
///
/// In production we lock to an explicit allowlist via `ALLOWED_ORIGINS` (a
/// comma-separated list of `https://…` origins). The `permissive()` fallback
/// only fires when the env var is unset — fine for local dev but a deploy-time
/// misconfiguration in production. The startup log makes which mode is active
/// visible.
fn build_cors_layer() -> tower_http::cors::CorsLayer {
    use tower_http::cors::{AllowOrigin, CorsLayer};
    match std::env::var("ALLOWED_ORIGINS").ok().filter(|s| !s.is_empty()) {
        Some(value) => {
            let origins: Vec<axum::http::HeaderValue> = value
                .split(',')
                .map(str::trim)
                .filter(|s| !s.is_empty())
                .filter_map(|s| s.parse().ok())
                .collect();
            info!(
                "CORS: allowlist mode — origins = {}",
                origins
                    .iter()
                    .filter_map(|o| o.to_str().ok())
                    .collect::<Vec<_>>()
                    .join(", ")
            );
            CorsLayer::new()
                .allow_origin(AllowOrigin::list(origins))
                .allow_methods([axum::http::Method::GET])
                .allow_headers([
                    axum::http::header::ACCEPT,
                    axum::http::header::CONTENT_TYPE,
                ])
        }
        None => {
            info!("CORS: permissive mode (set ALLOWED_ORIGINS in production!)");
            CorsLayer::permissive()
        }
    }
}

/// Extract a filesystem path from a `sqlite://...` URL, or `None` for non-file backends.
fn sqlite_path_from_url(url: &str) -> Option<std::path::PathBuf> {
    let stripped = url.strip_prefix("sqlite://")?;
    if stripped.starts_with(':') {
        // sqlite::memory: — no file
        return None;
    }
    // Remove any query string (e.g. `?mode=rwc`).
    let path = stripped.split('?').next()?;
    Some(std::path::PathBuf::from(path))
}
