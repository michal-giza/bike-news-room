# Bike News Room

Cycling news from around the world — road, MTB, gravel, track, and cyclocross — aggregated from public RSS feeds and websites of cycling publications, federations, and independent blogs. Refreshed every 30 minutes, deduplicated, classified by region and discipline.

**Live:** https://bike-news-room.pages.dev/
**Backend:** https://michal-giza-bike-news-room.hf.space/

---

## Why

Cycling fans miss smaller races and regional news because no single platform aggregates beyond the big events. War-room-style news feeds exist for geopolitics — nothing equivalent for cycling. This is the equivalent.

## Architecture

- **Backend:** Rust + Axum + SQLite (`backend/`), deployed to Hugging Face Spaces (Docker SDK).
- **Frontend:** Flutter Web with clean architecture per feature (`frontend/`), deployed to Cloudflare Pages.
- **Cost:** $0–1 / month at full capacity. See [DEPLOYMENT.md](DEPLOYMENT.md).

## Features

- 30-minute RSS + HTML-crawler ingestion across Poland, Spain, World feeds
- Dedup via SHA-256 title hash + Levenshtein fuzzy match
- Auto-growing source list — outbound links from articles surface candidate domains for review
- User-submitted source registration with SSRF guard, payload caps, rate limiting
- Daily digest email (Resend), one-click unsubscribe (RFC 8058)
- Twitter/X auto-poster (1.5/hr cap, dedup table)
- Live race ticker (admin-poke for now, PCS scraper next race week)
- Per-article OpenGraph stub HTML for social shares
- `/sitemap.xml` + `/robots.txt` + JSON-LD NewsArticle schema for SEO
- "What's new since you last visited" pill, skeleton loaders, infinite scroll
- Bookmarks, watchlist, calendar, region/discipline/category filters, full-text search
- Settings page: theme, density, reduced motion, redo onboarding, export bookmarks

## Repo layout

```
backend/                  Rust + Axum + SQLite
  src/
    domain/               Entities, ports (clean arch)
    application/          Use cases — ingest, dedup, digest, auto-tweet, etc.
    infrastructure/       Adapters — sqlite, rss, html_crawler, snapshot
    web/                  Axum routes, DTOs, error mapping, sitemap, OG html
  feeds.toml              Configured RSS sources
  Dockerfile              For HF Spaces

frontend/                 Flutter Web
  lib/
    core/                 di, network, theme, router, widgets
    features/
      feed/               Article feed, breaking panel, search, bookmarks
      preferences/        Theme, density, onboarding, settings
      sources/            User-submitted sources
      watchlist/          Following racers/teams
      calendar/           Upcoming races
      info/               About / Privacy / Terms
  web/                    PWA manifest, index.html, icons

scripts/                  Deploy + brand-icon generators
.github/workflows/        CI (cargo + flutter) + deploy
```

## Local development

### Backend

```sh
cd backend
cp .env.example .env       # set DATABASE_URL=sqlite:bike_news.db
cargo run
```

API listens on `http://localhost:7860`. Runs an initial RSS fetch + crawl on startup, then schedules every 30 minutes.

### Frontend

```sh
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:7860
```

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for full HF Spaces + Cloudflare Pages walkthrough.

Quick redeploys:
- Backend: `bash scripts/deploy-backend-hf.sh`
- Frontend: pushed to `main`, auto-builds on Cloudflare Pages.

## Configuration

Backend reads from environment variables. None are required to boot, but features stay dormant without them:

| Variable | Feature |
|---|---|
| `DATABASE_URL` | sqlite path (defaults to `sqlite:bike_news.db`) |
| `FRONTEND_ORIGIN` | Used in sitemap + email links |
| `BACKEND_ORIGIN` | Used in share URLs + unsubscribe links |
| `ADMIN_TOKEN` | Gates source-candidate promote/reject + live-ticker POST |
| `RESEND_API_KEY` | Daily digest sending |
| `DIGEST_FROM` | Optional `From` for digest emails |
| `TWITTER_OAUTH2_TOKEN` | Auto-tweet posting |
| `HF_TOKEN`, `HF_DATASET_ID` | DB snapshot persistence (see `infrastructure/snapshot.rs`) |
| `CORS_ALLOWED_ORIGINS` | Comma-separated allowlist (`*` for dev) |

## License

MIT — see [LICENSE](LICENSE).
