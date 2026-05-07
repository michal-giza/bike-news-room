---
title: Bike News Room — Source Crawler
emoji: 🕷
colorFrom: yellow
colorTo: gray
sdk: docker
app_port: 7860
pinned: false
---

# bnr-crawler

Light Rust service that runs on a **separate** Hugging Face Space from
the main backend. Polls the main API for pending source candidates,
probes each URL to decide whether it's an RSS feed or an HTML site we
can crawl, and posts a verdict back via the admin token.

## Why a second Space

The main backend serves the API + foreground feed; crawl bursts (HTML
fetch, parse, classify) can spike CPU for tens of seconds and stall
the live request path. Splitting them means:

- Crawler CPU spikes never affect API latency.
- Crawler crashes never bring the live feed down.
- HF's idle-sleep model (free tier sleeps after 48h idle) suits a
  cron-driven service like this perfectly.

Both services live behind their own HF Space; there's no shared
filesystem. Communication is one-way HTTPS with an admin-token-signed
callback to the main API.

## Required env vars

Set these in the HF Space settings → Variables:

| Var | Required | Default | Notes |
|---|---|---|---|
| `MAIN_API_BASE` | yes | – | `https://michal-giza-bike-news-room.hf.space` (no trailing slash) |
| `CRAWLER_TOKEN` | yes | – | Must match the main backend's `ADMIN_TOKEN` |
| `CRAWL_CRON` | no | `0 0 */6 * * *` | every 6 hours |
| `CRAWL_LIMIT` | no | `25` | max candidates per sweep |
| `RUST_LOG` | no | `info` | std env-filter syntax |

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | none | HF uptime check; returns `{"status":"ok"}` |
| POST | `/run` | none (rate-limited by HF) | Fire a sweep on demand. Returns the per-sweep stats JSON. |

## Local dev

```bash
cd bnr-crawler
RUST_LOG=info \
  MAIN_API_BASE=http://localhost:7860 \
  CRAWLER_TOKEN=local-dev-token \
  cargo run
```

The `/run` endpoint is the easiest way to test:

```bash
curl -X POST http://localhost:7860/run
# {"ok":true,"stats":{"fetched":3,"promoted":1,"rejected":1,"skipped":1}}
```

## Deploy to HF Space

```bash
hf repos create michal-giza/bnr-crawler --type space --space-sdk docker
git remote add hf-crawler https://huggingface.co/spaces/michal-giza/bnr-crawler
git subtree push --prefix=bnr-crawler hf-crawler main
```

Then set `MAIN_API_BASE` + `CRAWLER_TOKEN` in the Space settings.

## What it does NOT do

- It does not write to the main backend's database directly.
- It does not run the article-ingest pipeline; that stays on the main
  backend's 30-minute cron.
- It does not store any state — each sweep is independent. If the
  Space sleeps and wakes, the main API's `pending` queue still holds
  whatever candidates need processing.
