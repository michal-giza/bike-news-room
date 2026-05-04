//! Integration tests for the race-link feature: matcher → race_articles
//! → retention exemption → /api/articles?race_slug= path.

use std::sync::Arc;

use bike_news_room::application::QueryUseCases;
use bike_news_room::domain::entities::{ArticleDraft, ArticleQuery};
use bike_news_room::domain::ports::{ArticleRepository, FeedRepository, RaceLinkRepository};
use bike_news_room::infrastructure::{init_schema, SqliteRepository};
use sqlx::sqlite::SqlitePoolOptions;

async fn fresh_repo() -> Arc<SqliteRepository> {
    let pool = SqlitePoolOptions::new()
        .connect("sqlite::memory:")
        .await
        .unwrap();
    init_schema(&pool).await.unwrap();
    Arc::new(SqliteRepository::new(pool))
}

#[tokio::test]
async fn race_slug_query_filters_articles_to_links_only() {
    let repo = fresh_repo().await;
    // Seed a feed + 3 articles, link only one to a tracked race.
    let feed_id = repo
        .upsert("https://x.test/feed", "Test", "world", "road", "en")
        .await
        .unwrap();
    let mut article_ids = Vec::new();
    for (i, title) in ["A", "B", "C"].iter().enumerate() {
        let id = repo
            .insert(&ArticleDraft {
                feed_id,
                title: title.to_string(),
                description: None,
                url: format!("https://x.test/{i}"),
                image_url: None,
                published_at: format!("2026-04-{:02}T12:00:00+00:00", i + 1),
                title_hash: format!("h{i}"),
                category: None,
                region: "world".to_string(),
                discipline: "road".to_string(),
                language: "en".to_string(),
            })
            .await
            .unwrap()
            .unwrap();
        article_ids.push(id);
    }

    let race_id = repo
        .upsert_tracked_race("tour-de-france", "Tour de France", "road")
        .await
        .unwrap();
    repo.link_article(race_id, article_ids[1], "Tour de France")
        .await
        .unwrap();

    // Query with race_slug — only the linked article (B) returns.
    let queries = QueryUseCases::new(repo.clone(), repo.clone(), repo.clone());
    let q = ArticleQuery {
        page: 1,
        limit: 50,
        race_slug: Some("tour-de-france".to_string()),
        ..Default::default()
    };
    let (articles, total) = queries.list_articles(&q).await.unwrap();
    assert_eq!(total, 1);
    assert_eq!(articles.len(), 1);
    assert_eq!(articles[0].title, "B");
}

#[tokio::test]
async fn before_param_returns_articles_older_than_cutoff() {
    let repo = fresh_repo().await;
    let feed_id = repo
        .upsert("https://x.test/feed", "Test", "world", "road", "en")
        .await
        .unwrap();
    repo.insert(&ArticleDraft {
        feed_id,
        title: "old".into(),
        description: None,
        url: "https://x.test/old".into(),
        image_url: None,
        published_at: "2024-06-15T12:00:00+00:00".into(),
        title_hash: "h-old".into(),
        category: None,
        region: "world".into(),
        discipline: "road".into(),
        language: "en".into(),
    })
    .await
    .unwrap();
    repo.insert(&ArticleDraft {
        feed_id,
        title: "new".into(),
        description: None,
        url: "https://x.test/new".into(),
        image_url: None,
        published_at: "2026-04-15T12:00:00+00:00".into(),
        title_hash: "h-new".into(),
        category: None,
        region: "world".into(),
        discipline: "road".into(),
        language: "en".into(),
    })
    .await
    .unwrap();

    let queries = QueryUseCases::new(repo.clone(), repo.clone(), repo.clone());
    let q = ArticleQuery {
        page: 1,
        limit: 50,
        before: Some("2025-01-01T00:00:00+00:00".into()),
        ..Default::default()
    };
    let (articles, _) = queries.list_articles(&q).await.unwrap();
    assert_eq!(articles.len(), 1);
    assert_eq!(articles[0].title, "old");
}
