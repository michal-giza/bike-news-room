//! End-to-end API tests — wire the full stack with in-memory SQLite and
//! exercise it through Axum's `tower::Service`.

use std::sync::Arc;

use axum::body::Body;
use axum::http::{Request, StatusCode};
use bike_news_room::application::{AddUserSourceUseCase, BackfillArchiveUseCase, QueryUseCases};
use bike_news_room::domain::entities::{ArticleDraft, ArticleQuery};
use bike_news_room::domain::ports::{
    ArticleRepository, FeedRepository, SourceCandidateRepository, SubscriberRepository,
};
use bike_news_room::infrastructure::{init_schema, SqliteRepository};
use bike_news_room::web::create_router;
use http_body_util::BodyExt;
use serde_json::Value;
use sqlx::sqlite::SqlitePoolOptions;
use tower::ServiceExt;

async fn setup_app_with_seed() -> (axum::Router, Arc<SqliteRepository>) {
    let pool = SqlitePoolOptions::new()
        .connect("sqlite::memory:")
        .await
        .unwrap();
    init_schema(&pool).await.unwrap();
    let repo = Arc::new(SqliteRepository::new(pool.clone()));

    let feed_id = repo
        .upsert("https://test.com/feed", "TestFeed", "world", "road", "en")
        .await
        .unwrap();

    let articles = [
        ("Pogacar wins stage 5", "results", "world", "road"),
        ("New gravel bike review", "equipment", "world", "gravel"),
        ("Visma signs sprinter", "transfers", "world", "road"),
        ("Vuelta a España route revealed", "events", "spain", "road"),
        ("Polish cup results", "results", "poland", "mtb"),
    ];
    for (i, (title, cat, region, disc)) in articles.iter().enumerate() {
        repo.insert(&ArticleDraft {
            feed_id,
            title: title.to_string(),
            description: Some("desc".into()),
            url: format!("https://test.com/{i}"),
            image_url: None,
            published_at: format!("2026-05-{:02}T12:00:00+00:00", i + 1),
            title_hash: format!("h-{i}"),
            category: Some(cat.to_string()),
            region: region.to_string(),
            discipline: disc.to_string(),
            language: "en".to_string(),
        })
        .await
        .unwrap();
    }

    let queries = QueryUseCases::new(repo.clone(), repo.clone(), repo.clone());
    let add_source = Arc::new(AddUserSourceUseCase::new(repo.clone()));
    let candidates: Arc<dyn SourceCandidateRepository> = repo.clone();
    let subscribers: Arc<dyn SubscriberRepository> = repo.clone();
    (
        create_router(
            queries,
            add_source,
            candidates,
            subscribers,
            Arc::new(BackfillArchiveUseCase::new(
                repo.clone(),
                repo.clone(),
                repo.clone(),
                pool.clone(),
            )),
            pool,
        ),
        repo,
    )
}

async fn json_response(app: axum::Router, uri: &str) -> (StatusCode, Value) {
    let response = app
        .oneshot(Request::builder().uri(uri).body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = response.status();
    let body = response.into_body().collect().await.unwrap().to_bytes();
    let json: Value = serde_json::from_slice(&body).unwrap_or(Value::Null);
    (status, json)
}

#[tokio::test]
async fn health_returns_ok_with_article_count() {
    let (app, _) = setup_app_with_seed().await;
    let (status, body) = json_response(app, "/api/health").await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["status"], "ok");
    assert_eq!(body["article_count"], 5);
}

#[tokio::test]
async fn articles_endpoint_returns_all_by_default() {
    let (app, _) = setup_app_with_seed().await;
    let (status, body) = json_response(app, "/api/articles").await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["total"], 5);
    assert_eq!(body["page"], 1);
    assert_eq!(body["has_more"], false);
    assert_eq!(body["articles"].as_array().unwrap().len(), 5);
}

#[tokio::test]
async fn articles_endpoint_filters_by_region() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/articles?region=poland").await;
    assert_eq!(body["total"], 1);
    assert_eq!(body["articles"][0]["region"], "poland");
}

#[tokio::test]
async fn articles_endpoint_filters_by_discipline() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/articles?discipline=gravel").await;
    assert_eq!(body["total"], 1);
}

#[tokio::test]
async fn articles_endpoint_filters_by_category() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/articles?category=transfers").await;
    assert_eq!(body["total"], 1);
}

#[tokio::test]
async fn articles_endpoint_searches() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/articles?search=Pogacar").await;
    assert_eq!(body["total"], 1);
    assert!(body["articles"][0]["title"]
        .as_str()
        .unwrap()
        .contains("Pogacar"));
}

#[tokio::test]
async fn articles_endpoint_paginates() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/articles?limit=2&page=1").await;
    assert_eq!(body["articles"].as_array().unwrap().len(), 2);
    assert_eq!(body["has_more"], true);
}

#[tokio::test]
async fn articles_endpoint_clamps_limit() {
    let (app, _) = setup_app_with_seed().await;
    let (status, _) = json_response(app, "/api/articles?limit=9999").await;
    assert_eq!(status, StatusCode::OK);
}

#[tokio::test]
async fn article_by_id_returns_the_article() {
    let (app, repo) = setup_app_with_seed().await;
    let (articles, _) = repo
        .query(&ArticleQuery {
            page: 1,
            limit: 1,
            ..Default::default()
        })
        .await
        .unwrap();
    let id = articles[0].id;

    let (status, body) = json_response(app, &format!("/api/articles/{id}")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["id"], id);
}

#[tokio::test]
async fn article_by_id_returns_404_for_missing() {
    let (app, _) = setup_app_with_seed().await;
    let (status, _) = json_response(app, "/api/articles/99999").await;
    assert_eq!(status, StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn feeds_endpoint_returns_seeded() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/feeds").await;
    let feeds = body["feeds"].as_array().unwrap();
    assert_eq!(feeds.len(), 1);
    assert_eq!(feeds[0]["title"], "TestFeed");
}

#[tokio::test]
async fn categories_endpoint_aggregates() {
    let (app, _) = setup_app_with_seed().await;
    let (_, body) = json_response(app, "/api/categories").await;
    let cats = body["categories"].as_array().unwrap();
    let results = cats.iter().find(|c| c["category"] == "results").unwrap();
    assert_eq!(results["count"], 2);
}

#[tokio::test]
async fn metrics_endpoint_reports_feed_health() {
    let (app, repo) = setup_app_with_seed().await;

    // Bring TestFeed into "degraded" by incrementing errors a few times.
    let feed_id = repo.list_all().await.unwrap()[0].id;
    for _ in 0..4 {
        repo.increment_error(feed_id).await.unwrap();
    }

    let (status, body) = json_response(app, "/api/metrics").await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["article_count"], 5);
    assert_eq!(body["feed_count"], 1);
    assert_eq!(body["degraded_feeds"], 1);
    assert_eq!(body["healthy_feeds"], 0);
    assert_eq!(body["disabled_feeds"], 0);
    assert_eq!(body["feed_health"][0]["status"], "degraded");
    assert_eq!(body["feed_health"][0]["error_count"], 4);
}

#[tokio::test]
async fn empty_db_returns_empty_array() {
    let pool = SqlitePoolOptions::new()
        .connect("sqlite::memory:")
        .await
        .unwrap();
    init_schema(&pool).await.unwrap();
    let repo = Arc::new(SqliteRepository::new(pool.clone()));
    let queries = QueryUseCases::new(repo.clone(), repo.clone(), repo.clone());
    let add_source = Arc::new(AddUserSourceUseCase::new(repo.clone()));
    let candidates: Arc<dyn SourceCandidateRepository> = repo.clone();
    let subscribers: Arc<dyn SubscriberRepository> = repo.clone();
    let backfill = Arc::new(BackfillArchiveUseCase::new(
        repo.clone(),
        repo.clone(),
        repo.clone(),
        pool.clone(),
    ));
    let app = create_router(queries, add_source, candidates, subscribers, backfill, pool);

    let (status, body) = json_response(app, "/api/articles").await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["total"], 0);
    assert_eq!(body["articles"].as_array().unwrap().len(), 0);
}
