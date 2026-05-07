# Free enhancements (v1.3) — architecture + ops

Four features that ship with v1.3, all $0 ongoing cost. Covers what
they do, where the code lives, and what env vars / external accounts
each one needs.

---

## 1. Trending topics

**Endpoint**: `GET /api/trending?limit=10`

Pure SQL + Rust n-gram lift over a 24h window vs. a 7d baseline.
Stopwords (English filler + cycling boilerplate like "race", "stage",
"rider", "team") filtered out so the surfaced terms are the names +
events that actually spike day-to-day.

| Component | File |
|---|---|
| Use case | `backend/src/application/trending_use_case.rs` |
| Repo extension | `backend/src/domain/ports/article_repository.rs` (`titles_in_window`) |
| HTTP handler | `backend/src/web/routes.rs` (`get_trending`) |
| Frontend data source | `frontend/lib/features/feed/data/datasources/trending_remote_data_source.dart` |
| Cubit | `frontend/lib/features/feed/presentation/cubit/trending_cubit.dart` |
| UI | `frontend/lib/features/feed/presentation/widgets/trending_strip.dart` (chip strip above feed) |

**Cost**: $0. Pure SQL + in-process Rust. No external API.

**Operational tuning**: `min_recent_count` defaults to 2. Raise via
the use case constructor if the trending strip starts surfacing too
much noise on quiet days.

---

## 2. In-app reader

**Endpoint**: `GET /api/articles/{id}/reader`

On first request the backend GETs the article URL, runs a readability-
lite extractor (`<article>` first, then WordPress / Ghost selectors,
then generic `<main>` fallback), strips to plain text + paragraph
breaks, and caches in `articles.full_text`. Subsequent reads are
served from cache.

| Component | File |
|---|---|
| Use case | `backend/src/application/reader_use_case.rs` |
| Schema migration | `backend/src/infrastructure/sqlite_repository.rs` (added `articles.full_text TEXT`) |
| HTTP handler | `backend/src/web/routes.rs` (`get_article_reader`) |
| Frontend data source | `frontend/lib/features/feed/data/datasources/reader_remote_data_source.dart` |
| Cubit | `frontend/lib/features/feed/presentation/cubit/reader_cubit.dart` |
| UI | `_ReaderToggleBlock` in `article_detail_modal.dart` |

**Privacy / legal posture**:

- Honours `<meta name="robots" content="noarchive | noindex">` —
  publishers that opt out of mirroring don't get cached.
- The "Read on source" button stays prominent so click-through
  traffic still goes to the publisher.
- Cached body lives in the same row as the article headline, so the
  retention sweep removes it at the same TTL — we can't accidentally
  serve stale-publisher content for longer than the headline survives.

**Cost**: $0. The publisher GET is a one-shot per article, then
SQLite forever after.

---

## 3. Wikipedia rider/team/race context

**Endpoint**: `GET /api/wiki/{title}?lang=en`

Fetches Wikipedia REST `summary` for the entity. Caches the JSON
body for 7 days in a new `wiki_context` table (key on
`title|lang`). Locale-aware: tries the user's locale first then
falls back to English.

| Component | File |
|---|---|
| Use case | `backend/src/application/wiki_context_use_case.rs` |
| Schema | `backend/src/infrastructure/sqlite_repository.rs` (new `wiki_context` table) |
| HTTP handler | `backend/src/web/routes.rs` (`get_wiki_context`) |
| Frontend data source | `frontend/lib/features/watchlist/data/datasources/wiki_context_remote_data_source.dart` |
| UI | `WikiContextBlock` in `frontend/lib/features/watchlist/presentation/widgets/` |
| Wired into | `RaceDetailPage`. Future: rider/team detail pages once they exist as separate routes. |

**Cost**: $0. Wikipedia REST is public, no auth, ~200 req/s per IP
(we'll never approach that).

**Required HTTP header**: the use-case sends a User-Agent identifying
us with a contact link, per Wikipedia's API etiquette.

---

## 4. Daily Resend digest

The digest pipeline + cron were already shipped in earlier versions:
`backend/src/application/digest_use_case.rs` runs at `0 0 7 * * *` UTC
via `tokio_cron_scheduler` registered in `backend/src/main.rs:200+`.
The build-time wiring is complete; v1.3 just enables it operationally.

To go live, set the **`RESEND_API_KEY`** env var on the main HF Space:

1. Sign in / create a Resend account at <https://resend.com> (free tier:
   3,000 emails/month, 100/day — enough for our first ~3k subscribers).
2. Create an API key with "send" scope, scoped to a single domain.
3. Verify the sending domain. We currently send from
   `digest@bike-news-room.pages.dev` — Resend will give you DKIM +
   SPF DNS records to add to your Cloudflare zone.
4. Set the key in the HF Space:

   ```
   HF Space → Settings → Variables → New secret
     Name:  RESEND_API_KEY
     Value: re_xxx…
   ```

5. Optionally override the `From:` line via `DIGEST_FROM` if you want
   a different sender display name.

After the env var is set, the next 07:00 UTC fire sends. Without the
env var the cron runs but `DigestUseCase::execute` returns 0 emails
sent — visible in the HF Space logs.

**Cost**: $0 up to 3k emails/month (Resend free tier). Past that:
$20/month for 50k. We're well under for the foreseeable future.

---

## bnr-crawler — second HF Space

Lives in `bnr-crawler/` as a separate Cargo workspace. Polls the main
backend's `/api/sources/candidates?status=pending` queue every 6 hours
(or via `POST /run`), probes each URL to decide RSS vs HTML site, and
posts a verdict back to the main backend's
`/api/admin/source-candidates/{id}/{promote,reject}` endpoint with the
shared admin token.

See `bnr-crawler/README.md` for deploy steps.

**Why separate**: crawl bursts are CPU-spiky and would otherwise stall
the main backend's API request path. Splitting them means crawler
crashes can never bring the live feed down.

**Cost**: $0 — runs on the same HF Spaces free tier as the main
backend, separate Space. Sleeps after 48h idle, wakes on first
request, then runs the cron fires until next idle.

---

## What stayed out of v1.3

- **Internet Archive backfill** (`BackfillArchiveUseCase`): code
  exists, gated behind admin endpoint. One-shot operational task,
  not user-facing. Run manually when ready.
- **Live race-results**: deferred to v1.4 once we have the bnr-crawler
  proven in production.
- **Android / iOS home-screen widget**: requires native code; tracked
  for v1.4 with the slowik_app skill as reference.

## Verification

After deploying both Spaces, walk through this checklist:

```bash
# 1. Trending alive
curl -s 'https://michal-giza-bike-news-room.hf.space/api/trending?limit=5' \
  | jq '.terms | length'   # → 5 (or however many qualify)

# 2. Reader works on a recent article id
curl -s 'https://michal-giza-bike-news-room.hf.space/api/articles/<id>/reader' \
  | jq '{id: .article_id, len: (.full_text | length), cached: .from_cache}'

# 3. Wikipedia context for a known rider
curl -s 'https://michal-giza-bike-news-room.hf.space/api/wiki/Tadej%20Pogačar?lang=en' \
  | jq '{title, len: (.extract | length), thumb: .thumbnail_url}'

# 4. Crawler /run (manual sweep)
curl -X POST 'https://michal-giza-bnr-crawler.hf.space/run' | jq

# 5. Digest is wired (env var set on main Space)
# Cron runs at 07:00 UTC; check HF logs after the next fire.
```
