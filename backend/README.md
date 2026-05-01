---
title: Bike News Room API
emoji: 🚴
colorFrom: yellow
colorTo: red
sdk: docker
app_port: 7860
pinned: false
license: mit
short_description: Cycling news aggregator API. Read-only public.
---

# Bike News Room — Backend

Rust news aggregator for cycling. Fetches RSS feeds, crawls sites without RSS, deduplicates, categorizes, and serves over HTTP.

## Architecture (clean architecture / hexagonal)

```
src/
├── domain/              # Pure business logic — no I/O
│   ├── entities.rs      # Article, Feed, FeedHealth, ArticleQuery
│   ├── errors.rs        # DomainError + DomainResult
│   ├── ports/           # Trait abstractions
│   │   ├── article_repository.rs
│   │   ├── feed_repository.rs
│   │   ├── feed_fetcher.rs
│   │   └── web_crawler.rs
│   └── services/        # Pure functions: dedup, categorize
│
├── application/         # Use cases that orchestrate ports
│   ├── ingest_feeds_use_case.rs   # RSS pipeline + circuit breaker
│   ├── crawl_sites_use_case.rs    # HTML scrape pipeline
│   └── query_use_cases.rs         # Read-side for HTTP API
│
├── infrastructure/      # Concrete adapters
│   ├── sqlite_repository.rs       # impl ArticleRepository + FeedRepository
│   ├── rss_fetcher.rs             # impl FeedFetcher (reqwest + feed-rs)
│   ├── html_crawler.rs            # impl WebCrawler (reqwest + scraper)
│   ├── snapshot.rs                # Optional DB snapshot/restore for HF Spaces
│   └── config.rs                  # AppConfig (feeds.toml)
│
├── web/                 # HTTP layer (Axum)
│   ├── routes.rs        # Route handlers calling use cases
│   ├── dto.rs           # Request/response types
│   ├── errors.rs        # DomainError → HTTP status
│   └── crawl_targets.rs # Hard-coded crawl targets
│
├── lib.rs               # Module exports
└── main.rs              # Composition root — DI wiring
```

The dependency rule: outer layers depend on inner. `web` and `infrastructure` know about `domain`; `domain` knows nothing of either.

## Running locally

```bash
cargo run --release
# Server on http://localhost:7860
# DB: ./bike_news.db
```

## Configuration (env vars)

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT` | `7860` | HTTP listen port |
| `DATABASE_URL` | `sqlite://bike_news.db?mode=rwc` | SQLite location |
| `FEEDS_PATH` | `feeds.toml` | RSS feed config |
| `LOG_FORMAT` | (text) | Set to `json` for structured logs |
| `RUST_LOG` | (info) | tracing filter |
| `SNAPSHOT_URL` | — | Enables periodic DB upload to this HTTP endpoint |
| `SNAPSHOT_TOKEN` | — | Bearer token for snapshot endpoint |
| `SNAPSHOT_INTERVAL_MINUTES` | `60` | Snapshot frequency |

## API

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/articles` | List articles with filters (`region`, `discipline`, `category`, `search`, `since`, `page`, `limit`) |
| GET | `/api/articles/{id}` | Single article |
| GET | `/api/feeds` | All registered feeds |
| GET | `/api/categories` | Category counts |
| GET | `/api/health` | Liveness + article count + last fetch |
| GET | `/api/metrics` | Detailed metrics: per-feed health, categories, uptime |

## Reliability features

- **Circuit breaker:** feeds with `error_count >= 10` are auto-skipped (`FeedHealth::Disabled`)
- **Rate limiting:** per-IP, 10 req/s with burst of 50 (`tower_governor`)
- **Deduplication:** URL-unique constraint + SHA256 title hash + Levenshtein fuzzy match
- **Graceful errors:** typed `DomainError` propagation, no silent `unwrap` chains
- **Snapshots:** optional DB backup/restore for ephemeral hosts (HF Spaces)

## Testing

```bash
cargo test           # All 64 tests
cargo fmt --check
cargo clippy --all-targets -- -D warnings
```

Tests are organized as:
- **Unit tests** (in source files): pure logic — categorizer, dedup, FeedHealth, HTML extractor (33 tests)
- **`tests/db_integration.rs`**: SQLite repository through port traits (11 tests)
- **`tests/api_integration.rs`**: full Axum stack with in-memory SQLite (14 tests)
- **`tests/use_case_tests.rs`**: use cases with full trait mocks — circuit breaker, dedup pipeline (5 tests)

## Adding a new feed

**RSS source** — add to `feeds.toml`:
```toml
[[feeds]]
url = "https://example.com/rss"
title = "Example"
region = "world"      # poland | spain | world | eu
discipline = "road"   # road | mtb | gravel | track | cx | all
language = "en"
```

**HTML-only source** — add to `src/web/crawl_targets.rs` with CSS selectors:
```rust
CrawlTarget {
    name: "Example".into(),
    url: "https://example.com/news".into(),
    region: "world".into(),
    discipline: "road".into(),
    language: "en".into(),
    selectors: CrawlSelectors {
        article_list: "article.news-card".into(),
        title: "h2 a".into(),
        link: "h2 a".into(),
        description: Some(".excerpt".into()),
        image: Some("img".into()),
        date: Some("time".into()),
        relative_links: true,
    },
},
```

## Deployment

The included `Dockerfile` builds a minimal Debian-slim image. Hugging Face Spaces (Docker SDK) auto-deploys on push to `main` once `.github/workflows/deploy.yml` secrets are configured (`HF_TOKEN`, `HF_USER`, `HF_SPACE`).
