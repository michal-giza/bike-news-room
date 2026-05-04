//! Integration tests for the SQLite repository, exercising it through the
//! domain port traits (the same way use cases do).

use std::sync::Arc;

use bike_news_room::domain::entities::{ArticleDraft, ArticleQuery, RaceDraft};
use bike_news_room::domain::ports::{ArticleRepository, FeedRepository, RaceRepository};
use bike_news_room::infrastructure::{init_schema, SqliteRepository};
use sqlx::sqlite::SqlitePoolOptions;

async fn setup_repo() -> Arc<SqliteRepository> {
    let pool = SqlitePoolOptions::new()
        .max_connections(1)
        .connect("sqlite::memory:")
        .await
        .expect("connect");
    init_schema(&pool).await.expect("init schema");
    Arc::new(SqliteRepository::new(pool))
}

async fn seed_feed(repo: &SqliteRepository) -> i64 {
    repo.upsert("https://example.com/feed", "Example", "world", "road", "en")
        .await
        .unwrap()
}

fn draft(
    feed_id: i64,
    suffix: &str,
    region: &str,
    discipline: &str,
    category: Option<&str>,
) -> ArticleDraft {
    ArticleDraft {
        feed_id,
        title: format!("Title {suffix}"),
        description: Some("desc".to_string()),
        url: format!("https://example.com/{suffix}"),
        image_url: None,
        published_at: "2026-05-01T12:00:00+00:00".to_string(),
        title_hash: format!("hash-{suffix}"),
        category: category.map(String::from),
        region: region.to_string(),
        discipline: discipline.to_string(),
        language: "en".to_string(),
    }
}

#[tokio::test]
async fn schema_creates_empty_db() {
    let repo = setup_repo().await;
    assert_eq!(repo.count().await.unwrap(), 0);
}

#[tokio::test]
async fn upsert_feed_returns_stable_id() {
    let repo = setup_repo().await;
    let id1 = seed_feed(&repo).await;
    let id2 = seed_feed(&repo).await;
    assert_eq!(id1, id2);
}

#[tokio::test]
async fn insert_article_persists_data() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    let id = repo
        .insert(&draft(feed_id, "1", "world", "road", Some("results")))
        .await
        .unwrap()
        .unwrap();

    let article = repo.find_by_id(id).await.unwrap().unwrap();
    assert_eq!(article.title, "Title 1");
    assert_eq!(article.category.as_deref(), Some("results"));
}

#[tokio::test]
async fn url_unique_constraint_prevents_duplicates() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    repo.insert(&draft(feed_id, "x", "world", "road", None))
        .await
        .unwrap();

    // Second insert with same URL but different content — INSERT OR IGNORE returns None.
    let mut d2 = draft(feed_id, "x", "world", "road", None);
    d2.title = "Different".to_string();
    d2.title_hash = "different-hash".to_string();
    let result = repo.insert(&d2).await.unwrap();

    assert_eq!(result, None);
    assert_eq!(repo.count().await.unwrap(), 1);
}

#[tokio::test]
async fn hash_exists_detects_existing_hash() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    repo.insert(&draft(feed_id, "y", "world", "road", None))
        .await
        .unwrap();

    assert!(repo.hash_exists("hash-y").await.unwrap());
    assert!(!repo.hash_exists("nope").await.unwrap());
}

#[tokio::test]
async fn query_filters_by_region() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    for (i, region) in ["world", "world", "poland", "spain", "spain"]
        .iter()
        .enumerate()
    {
        repo.insert(&draft(
            feed_id,
            &i.to_string(),
            region,
            "road",
            Some("general"),
        ))
        .await
        .unwrap();
    }

    let q = ArticleQuery {
        page: 1,
        limit: 10,
        region: Some("spain".into()),
        ..Default::default()
    };
    let (articles, total) = repo.query(&q).await.unwrap();
    assert_eq!(total, 2);
    assert!(articles
        .iter()
        .all(|a| a.region.as_deref() == Some("spain")));
}

#[tokio::test]
async fn query_filters_by_search_term() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;

    let titles = [
        "Pogacar wins stage 5",
        "New gravel bike review",
        "Vingegaard takes pink",
    ];
    for (i, title) in titles.iter().enumerate() {
        let mut d = draft(feed_id, &i.to_string(), "world", "road", None);
        d.title = title.to_string();
        repo.insert(&d).await.unwrap();
    }

    let q = ArticleQuery {
        page: 1,
        limit: 10,
        search: Some("gravel".into()),
        ..Default::default()
    };
    let (articles, total) = repo.query(&q).await.unwrap();
    assert_eq!(total, 1);
    assert_eq!(articles[0].title, "New gravel bike review");
}

#[tokio::test]
async fn query_excludes_duplicates() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    let canonical = repo
        .insert(&draft(feed_id, "a", "world", "road", None))
        .await
        .unwrap()
        .unwrap();
    let dup = repo
        .insert(&draft(feed_id, "b", "world", "road", None))
        .await
        .unwrap()
        .unwrap();

    repo.mark_duplicate(dup, canonical).await.unwrap();

    let (articles, total) = repo
        .query(&ArticleQuery {
            page: 1,
            limit: 10,
            ..Default::default()
        })
        .await
        .unwrap();
    assert_eq!(total, 1);
    assert_eq!(articles[0].id, canonical);
}

#[tokio::test]
async fn query_paginates() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;

    for i in 0..25 {
        let mut d = draft(feed_id, &i.to_string(), "world", "road", None);
        d.published_at = format!("2026-05-{:02}T12:00:00+00:00", (i % 28) + 1);
        repo.insert(&d).await.unwrap();
    }

    let p1 = repo
        .query(&ArticleQuery {
            page: 1,
            limit: 10,
            ..Default::default()
        })
        .await
        .unwrap();
    let p2 = repo
        .query(&ArticleQuery {
            page: 2,
            limit: 10,
            ..Default::default()
        })
        .await
        .unwrap();

    assert_eq!(p1.0.len(), 10);
    assert_eq!(p2.0.len(), 10);
    assert_eq!(p1.1, 25);

    let p1_ids: Vec<_> = p1.0.iter().map(|a| a.id).collect();
    let p2_ids: Vec<_> = p2.0.iter().map(|a| a.id).collect();
    assert!(p1_ids.iter().all(|id| !p2_ids.contains(id)));
}

#[tokio::test]
async fn category_counts_aggregate_correctly() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    for (i, cat) in ["results", "results", "results", "transfers", "equipment"]
        .iter()
        .enumerate()
    {
        repo.insert(&draft(feed_id, &i.to_string(), "world", "road", Some(cat)))
            .await
            .unwrap();
    }

    let counts = repo.category_counts().await.unwrap();
    assert_eq!(
        counts
            .iter()
            .find(|c| c.category == "results")
            .unwrap()
            .count,
        3
    );
    assert_eq!(
        counts
            .iter()
            .find(|c| c.category == "transfers")
            .unwrap()
            .count,
        1
    );
}

#[tokio::test]
async fn search_escapes_like_wildcards() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;

    let titles = [
        "Article about 100% climbs",
        "Pogacar wins stage",
        "Anything goes",
    ];
    for (i, title) in titles.iter().enumerate() {
        let mut d = draft(feed_id, &i.to_string(), "world", "road", None);
        d.title = title.to_string();
        repo.insert(&d).await.unwrap();
    }

    // "100%" should match exactly one — not three. The `%` must be escaped
    // before being interpolated into the LIKE pattern.
    let q = ArticleQuery {
        page: 1,
        limit: 10,
        search: Some("100%".to_string()),
        ..Default::default()
    };
    let (articles, total) = repo.query(&q).await.unwrap();
    assert_eq!(total, 1);
    assert_eq!(articles[0].title, "Article about 100% climbs");

    // Underscore is also a LIKE wildcard — confirm it's escaped too.
    let q2 = ArticleQuery {
        page: 1,
        limit: 10,
        search: Some("a_b".to_string()),
        ..Default::default()
    };
    let (_articles, total2) = repo.query(&q2).await.unwrap();
    assert_eq!(total2, 0);
}

#[tokio::test]
async fn cluster_count_matches_number_of_duplicates() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;

    let canonical = repo
        .insert(&draft(feed_id, "canonical", "world", "road", None))
        .await
        .unwrap()
        .unwrap();

    // 3 duplicates pointing at the canonical article.
    for i in 0..3 {
        let dup_id = repo
            .insert(&draft(feed_id, &format!("d{i}"), "world", "road", None))
            .await
            .unwrap()
            .unwrap();
        repo.mark_duplicate(dup_id, canonical).await.unwrap();
    }

    let article = repo.find_by_id(canonical).await.unwrap().unwrap();
    assert_eq!(article.cluster_count, 3);
}

// ─── Race repository ───────────────────────────────────────────────────

fn race_draft(name: &str, start: &str, discipline: &str) -> RaceDraft {
    RaceDraft {
        name: name.to_string(),
        start_date: start.to_string(),
        end_date: None,
        country: Some("FR".to_string()),
        category: Some("2.UWT".to_string()),
        discipline: discipline.to_string(),
        url: Some("https://example.com".to_string()),
    }
}

#[tokio::test]
async fn race_upsert_is_idempotent_on_natural_key() {
    let repo = setup_repo().await;
    let id1 = repo
        .upsert_race(&race_draft("Tour de France", "2026-07-04", "road"))
        .await
        .unwrap();
    let id2 = repo
        .upsert_race(&race_draft("Tour de France", "2026-07-04", "road"))
        .await
        .unwrap();
    assert_eq!(id1, id2);
    assert_eq!(repo.count_races().await.unwrap(), 1);
}

#[tokio::test]
async fn race_upcoming_excludes_past_races_and_filters_by_discipline() {
    let repo = setup_repo().await;
    let yesterday = (chrono::Utc::now() - chrono::Duration::days(1))
        .format("%Y-%m-%d")
        .to_string();
    let tomorrow = (chrono::Utc::now() + chrono::Duration::days(1))
        .format("%Y-%m-%d")
        .to_string();
    let next_week = (chrono::Utc::now() + chrono::Duration::days(7))
        .format("%Y-%m-%d")
        .to_string();

    repo.upsert_race(&race_draft("Past Race", &yesterday, "road"))
        .await
        .unwrap();
    repo.upsert_race(&race_draft("Future Road", &tomorrow, "road"))
        .await
        .unwrap();
    repo.upsert_race(&race_draft("Future MTB", &next_week, "mtb"))
        .await
        .unwrap();

    let road = repo.upcoming_races(Some("road"), 10).await.unwrap();
    assert_eq!(road.len(), 1);
    assert_eq!(road[0].name, "Future Road");

    let all = repo.upcoming_races(None, 10).await.unwrap();
    assert_eq!(all.len(), 2);
    // Sorted by start_date ascending — the road race comes first.
    assert_eq!(all[0].name, "Future Road");
    assert_eq!(all[1].name, "Future MTB");
}

#[tokio::test]
async fn cluster_count_is_zero_when_no_duplicates() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;
    let id = repo
        .insert(&draft(feed_id, "solo", "world", "road", None))
        .await
        .unwrap()
        .unwrap();
    let article = repo.find_by_id(id).await.unwrap().unwrap();
    assert_eq!(article.cluster_count, 0);
}

#[tokio::test]
async fn feed_error_count_increments_and_resets() {
    let repo = setup_repo().await;
    let feed_id = seed_feed(&repo).await;

    repo.increment_error(feed_id).await.unwrap();
    repo.increment_error(feed_id).await.unwrap();

    let feed = repo
        .list_all()
        .await
        .unwrap()
        .into_iter()
        .find(|f| f.id == feed_id)
        .unwrap();
    assert_eq!(feed.error_count, 2);

    repo.mark_fetched(feed_id).await.unwrap();
    let feed = repo
        .list_all()
        .await
        .unwrap()
        .into_iter()
        .find(|f| f.id == feed_id)
        .unwrap();
    assert_eq!(feed.error_count, 0);
    assert!(feed.last_fetched_at.is_some());
}
