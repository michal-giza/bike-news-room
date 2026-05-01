# Bike News Room — Deployment Runbook

End-to-end guide to ship the project from local dev → public production:

- **Backend** (Rust + SQLite) → **Hugging Face Spaces** (Docker SDK), free tier
- **Frontend** (Flutter Web) → **Cloudflare Pages**, free tier

Total cost target: **$0–1 / month**.

---

## 0. Prerequisites (one-time setup)

| Item | Why | How |
|---|---|---|
| GitHub account | Source of truth + CI | https://github.com/signup |
| Hugging Face account | Backend host | https://huggingface.co/join |
| Cloudflare account | Frontend host + DNS | https://dash.cloudflare.com/sign-up |
| `git`, `gh` (GitHub CLI) | Local push + repo creation | `brew install gh` |
| Local toolchain | Pre-deploy verification | Already installed: Rust 1.95, Flutter 3.41 |

Optional but recommended:
- **A custom domain** (e.g. `bikenewsroom.com`) — pointed at Cloudflare for DNS.

---

## 1. Pre-deploy verification (do this every time)

Run all gates locally before pushing. If any fail, do **not** deploy.

```bash
# ── Backend ──────────────────────────────────────────
cd backend
cargo fmt --all -- --check          # style
cargo clippy --all-targets -- -D warnings   # lints
cargo test --all                    # 73 tests should pass
cargo build --release               # produces target/release/bike-news-room

# ── Frontend ─────────────────────────────────────────
cd ../frontend
flutter analyze                     # 0 issues
flutter test                        # 70 tests should pass
flutter build web --release         # produces build/web/
```

**Smoke test the local stack** (catches integration breakage tests miss):

```bash
# Terminal 1 — backend
cd backend
./target/release/bike-news-room &
sleep 8
curl -s http://localhost:7860/api/health | jq .
# Expect: { "status": "ok", "article_count": >0, ... }

# Terminal 2 — frontend (build, then serve)
cd frontend/build/web
python3 -m http.server 8080 &
open http://localhost:8080
# Click around: feed loads, search ⌘K, follow rider, open detail modal
```

When everything looks right: **commit and push**.

---

## 2. First push to GitHub

If the project isn't on GitHub yet:

```bash
cd /Users/michalgiza/Desktop/bike_news_room
git init -b main
git add .
git status                         # SANITY CHECK — confirm no .env, no *.db, no target/
git commit -m "Initial commit"
gh repo create bike-news-room --public --source=. --remote=origin --push
```

If it's already there: just `git push`.

---

## 3. Backend → Hugging Face Spaces

### 3.1 Create the Space

```bash
# Either via web at https://huggingface.co/new-space:
#   - Owner: <your-hf-username>
#   - Space name: bike-news-room
#   - License: MIT (or your choice)
#   - SDK: Docker  ← important
#   - Hardware: CPU basic (free tier: 2 vCPU, 16 GB RAM)
#   - Visibility: Public

# Or via CLI (after `pip install huggingface_hub` and `huggingface-cli login`):
huggingface-cli repo create bike-news-room --type space --space_sdk docker
```

### 3.2 Configure the Space's `README.md` frontmatter

Hugging Face uses YAML frontmatter on the README to know which port to expose, what SDK, etc. Add this to the **root** of the repo (or to a separate `huggingface/README.md` if you want to push only the backend):

```yaml
---
title: Bike News Room API
emoji: 🚴
colorFrom: yellow
colorTo: red
sdk: docker
app_port: 7860
pinned: false
---
```

### 3.3 Adjust the Dockerfile for Spaces (if needed)

The current `backend/Dockerfile` listens on port 7860 — matches HF's default. Verify:

```bash
grep -E "(EXPOSE|CMD)" backend/Dockerfile
# EXPOSE 7860
# CMD ["bike-news-room"]
```

**Important:** HF Spaces requires the Dockerfile at **repo root**, not in a subdir. You have two options:

**Option A (recommended): backend-only Space repo.**
Push only the `backend/` contents to the HF Space repo. The frontend stays in the GitHub repo.

**Option B: monorepo with a root Dockerfile that builds the backend.**
Add a root `Dockerfile` that does `WORKDIR backend && cargo build --release`. Slower builds but keeps one repo.

We'll use **Option A** below — cleaner.

### 3.4 Push the backend to HF Spaces

```bash
# Add HF as a second remote on a backend-only branch.
cd /Users/michalgiza/Desktop/bike_news_room

# Create a Git subtree push of just the backend/ folder.
git subtree split --prefix=backend -b hf-backend
git push https://huggingface.co/spaces/<your-hf-user>/bike-news-room \
  hf-backend:main --force

# Hugging Face will auto-build the Docker image — visit the Space page to watch.
```

The first build takes ~5 minutes (downloads + compiles all Rust deps).

### 3.5 Configure Space environment variables

In the Space settings → **Variables and secrets** page, add:

| Name | Value | Why |
|---|---|---|
| `ALLOWED_ORIGINS` | `https://<your-pages-subdomain>.pages.dev,https://<your-domain>` | Locks CORS — replaces `permissive` mode |
| `LOG_FORMAT` | `json` | Structured logs for HF's log viewer |
| `RUST_LOG` | `bike_news_room=info` | Reasonable verbosity |
| `DATABASE_URL` | `sqlite:///data/bike_news.db?mode=rwc` | Persistent volume location |

Optional (only if you set up an external snapshot bucket):

| Name | Value |
|---|---|
| `SNAPSHOT_URL` | `https://your-bucket/bike_news.db` |
| `SNAPSHOT_TOKEN` | bearer token for that endpoint |
| `SNAPSHOT_INTERVAL_MINUTES` | `60` |

Click **Save** — the Space restarts with the new env.

### 3.6 Verify the deployed backend

```bash
# Replace with your Space subdomain (visible at the top of the Space page).
export HF=https://<your-hf-user>-bike-news-room.hf.space

# Health
curl -s $HF/api/health | jq .
# Expect: { "status":"ok", "article_count":<rising>, ... }

# CORS lockdown — must reject foreign origins:
curl -s -i -H "Origin: https://evil.example.com" $HF/api/articles | grep -i access-control
# Expect: NO Access-Control-Allow-Origin header (rejected by allowlist)

curl -s -i -H "Origin: https://<your-pages-subdomain>.pages.dev" $HF/api/articles | grep -i access-control
# Expect: Access-Control-Allow-Origin: https://<your-pages-subdomain>.pages.dev

# Security headers
curl -s -i $HF/api/health | grep -Ei "(x-content-type|x-frame|content-security|referrer)"
# Expect all four set
```

If anything is off, check the Space's **Logs** tab.

---

## 4. Frontend → Cloudflare Pages

### 4.1 Tell the frontend where the API lives

The Flutter app reads `API_BASE_URL` at compile time via `--dart-define`. We set it on the build step.

### 4.2 Connect the GitHub repo to Cloudflare Pages

1. Cloudflare dashboard → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**.
2. Select the `bike-news-room` GitHub repo.
3. Configure the build:

| Setting | Value |
|---|---|
| Production branch | `main` |
| Framework preset | None |
| Build command | `cd frontend && flutter build web --release --dart-define=API_BASE_URL=https://<your-hf-user>-bike-news-room.hf.space` |
| Build output directory | `frontend/build/web` |
| Root directory | (leave empty — repo root) |

4. Add an **environment variable** for the build:

| Name | Value |
|---|---|
| `FLUTTER_VERSION` | `3.41.7` |

5. The build will fail on the first run because Cloudflare's default image doesn't have Flutter. Add a **build script** at the repo root:

```bash
# scripts/cloudflare-build.sh
#!/usr/bin/env bash
set -euo pipefail
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PWD/_flutter/bin:$PATH"
flutter --version
flutter pub get -C frontend
cd frontend && flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:-https://localhost:7860}"
```

Then set the build command to `bash scripts/cloudflare-build.sh`.

6. Trigger a deploy — Cloudflare will build + serve at `https://bike-news-room.pages.dev`.

### 4.3 Add a `_headers` file for production CSP

Cloudflare Pages serves a static file `frontend/web/_headers` (after build it ends up in `frontend/build/web/_headers`) with HTTP headers per path. Create it before building:

```
# frontend/web/_headers
/*
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: no-referrer
  Permissions-Policy: camera=(), microphone=(), geolocation=()
```

The CSP is already in `index.html`'s `<meta>`; if you want to set it as a real header instead (more authoritative), add it here and remove the meta tag.

### 4.4 (Optional) Custom domain

In Cloudflare Pages → your project → **Custom domains** → **Set up a custom domain**.
Cloudflare handles DNS + HTTPS automatically.

Update the backend's `ALLOWED_ORIGINS` env var (Section 3.5) to include the custom domain.

---

## 5. Post-deploy testing checklist

Walk through these in your browser at the production URL. Each must pass before announcing.

### Functional
- [ ] Home feed loads articles within 2 seconds of first paint
- [ ] Live article count + "UPDATED Xm ago" timestamp shows real recent data
- [ ] Filter sidebar (or drawer on mobile) filters work for region/discipline/category
- [ ] `⌘K` (or click search icon) opens search overlay; typing returns matches
- [ ] Search overlay shows "+ FOLLOW" suggestions when typing rider name
- [ ] Following a rider, refreshing — WATCHING badge appears on matching articles
- [ ] Following page lists watched riders with × to unfollow + matching articles below
- [ ] Tap article card → modal opens, no yellow underlines, no raw HTML in summary
- [ ] "Read on [Source]" button opens the article in a new tab
- [ ] Bookmark icon adds article to /SAVED tab; persists across browser refresh
- [ ] /RACES tab shows the upcoming race calendar grouped by month
- [ ] Discipline filter chips on calendar work
- [ ] Mobile (resize browser to 375px wide):
  - [ ] Sidebar hidden, bottom nav visible (FEED · FOLLOWING · SEARCH · RACES · SAVED)
  - [ ] FAB opens filter drawer
  - [ ] Modal becomes a bottom-sheet instead of centered card
- [ ] Onboarding 3-step flow runs on first visit only (clear localStorage to retest)

### Operational
- [ ] `/api/health` reports `article_count > 100` within 30 minutes of cold boot
- [ ] `/api/metrics` shows ≥ 80% of feeds with `status: "healthy"`
- [ ] HF Spaces logs show `feed scheduler started (RSS+crawl every 30m, calendar 03:00 daily)`
- [ ] No `ERROR` lines in HF logs after first 10 minutes
- [ ] Cloudflare Pages **Analytics** shows the JS bundle being served compressed (Brotli)

### Security
- [ ] `curl -i $HF/api/health` shows: `x-content-type-options: nosniff`, `x-frame-options: DENY`, `referrer-policy: no-referrer`, `content-security-policy: default-src 'none'; frame-ancestors 'none'`
- [ ] `curl -i -H "Origin: https://evil.example.com" $HF/api/articles` does NOT include `Access-Control-Allow-Origin`
- [ ] In browser devtools Network tab, the loaded `index.html` has the CSP `<meta>` (or header)
- [ ] Hammering with `for i in $(seq 1 100); do curl -s $HF/api/articles >/dev/null; done` triggers a 429 from `tower_governor`

---

## 6. Operating the live system

### Logs
Hugging Face Spaces → your Space → **Logs** tab. Set `LOG_FORMAT=json` for filtering with `jq`.

### Restarting the backend
HF Spaces → **Settings** → **Factory reboot** (clears the SQLite DB) or **Restart** (preserves data only if persistent storage is enabled).

If you need persistence, enable HF persistent storage in Space settings (free 5 GB). Otherwise wire `SNAPSHOT_URL` to a backup endpoint.

### Adding a new feed
1. Edit `backend/feeds.toml` locally → add the new `[[feeds]]` block.
2. `cargo test` (still passes — feed config is data, not code).
3. `git push` and re-run the HF subtree push (Section 3.4).
4. After deploy, verify in `/api/feeds` that it's listed and `error_count: 0` after the next ingest cycle.

### Watching for broken feeds
`/api/metrics` shows `feed_health[]`. Anything with `status: "disabled"` (error_count ≥ 10) was auto-skipped by the circuit breaker. Either fix its URL or remove from `feeds.toml`.

### Updating
1. Make changes locally.
2. Run Section 1's pre-deploy verification.
3. `git push origin main` — Cloudflare Pages auto-rebuilds the frontend.
4. `git subtree split --prefix=backend -b hf-backend && git push <hf-remote> hf-backend:main --force` — HF rebuilds the backend.
5. Run Section 5's post-deploy checklist.

---

## 7. Rollback

### Frontend
Cloudflare Pages → your project → **Deployments** → click any past deployment → **Rollback to this deployment**.

### Backend
HF Spaces stores no Git history of force-pushes (we use `--force` to update the Space). Rollback = re-push the previous commit:

```bash
git checkout <last-good-commit>
git subtree split --prefix=backend -b hf-rollback
git push <hf-remote> hf-rollback:main --force
git checkout main
```

---

## 8. Troubleshooting cheat-sheet

| Symptom | Likely cause | Fix |
|---|---|---|
| Frontend shows "Couldn't reach the news room" | API_BASE_URL wrong or CORS blocking | Verify `--dart-define` value matches HF Space URL exactly; check `ALLOWED_ORIGINS` env contains your Pages URL |
| Article cards say "Source" instead of real publisher | `/api/feeds` returned empty or errored | Check `/api/feeds` directly; check Space logs for SQL errors |
| All articles have no images | Image URLs from feeds are http:// (mixed content blocks them on https:// site) | Browser security — feeds must serve https images. Consider proxying through your backend later |
| Yellow underlines on text in modals | Old build cached in browser | Hard reload (Cmd+Shift+R) |
| `cargo build` fails on HF | Space ran out of memory during link | Switch to "CPU upgrade" hardware tier ($0.60/hr) just for the build, then back |
| Calendar empty | First sync hasn't run yet | Wait 5 min after cold boot, or hit `/api/health` to confirm uptime > 60s |
| Bottom-nav route navigates but blank | A new dev pushed code that broke a `BlocProvider` chain | Check browser console + add a regression test |
| 429 Too Many Requests | Rate limiter kicked in | Expected behaviour — back off; tune `governor` config if too aggressive |

---

## 9. Costs at this scale (recurring)

| Service | Tier | Monthly cost |
|---|---|---|
| Hugging Face Spaces (CPU basic, public) | Free | $0 |
| Cloudflare Pages | Free | $0 |
| Custom domain (.com) | Yearly via Cloudflare Registrar | ~$10/year |
| GitHub | Free | $0 |
| **Total** | | **~$1/month amortised** |

Scale-up triggers (if you grow): Cloudflare Pages stays free indefinitely for static assets; HF Spaces may need persistent storage ($5/mo for 20 GB) once daily ingests fill the DB.

---

## 10. What we explicitly did NOT do (and why)

- **AI summaries**: paid OpenAI/Claude API call per article would cost $5–15/mo; user requested cost-free build.
- **i18n / translation**: deferred — most cycling content is in EN; bring this back when PL/ES audience grows.
- **Auth / accounts**: by design — bookmarks + watchlist live in browser `localStorage`. Lower friction, zero compliance burden, no PII at rest.
- **Mobile native apps**: web-first launch. When ready: `flutter create . --platforms=android,ios --org com.majksquare`.

---

## Appendix A: Repo layout reference

```
bike_news_room/
├── backend/                  ← Rust API + ingestion (deploys to HF Spaces)
│   ├── Cargo.toml
│   ├── Dockerfile
│   ├── feeds.toml
│   ├── src/
│   │   ├── domain/           clean architecture: entities, ports, services
│   │   ├── application/      use cases (ingest, crawl, sync calendar, queries)
│   │   ├── infrastructure/   SQLite repo, RSS fetcher, HTML crawler, scrape
│   │   ├── web/              Axum routes + DTOs + error mapping
│   │   ├── lib.rs / main.rs
│   └── tests/                73 tests: unit + DB + API + use-case mocks
├── frontend/                 ← Flutter Web (deploys to Cloudflare Pages)
│   ├── pubspec.yaml
│   ├── web/
│   │   ├── index.html        CSP + Open Graph
│   │   └── manifest.json
│   ├── assets/
│   │   └── catalogue/watchlist_seed.json   bundled rider/team list
│   ├── lib/
│   │   ├── core/             theme tokens, network, errors, url safety
│   │   └── features/
│   │       ├── feed/         articles, search, breaking panel, bottom nav
│   │       ├── calendar/     race calendar
│   │       ├── watchlist/    follow riders/teams (FOLLOWING tab)
│   │       └── preferences/  theme, persona, density, onboarding
│   └── test/                 70 tests
├── DEPLOYMENT.md             ← you are here
├── DESIGNER_PROMPT.md        original designer brief
└── .github/workflows/        CI (fmt, clippy, test, build) + deploy
```

## Appendix B: Quick command reference

```bash
# Local dev
( cd backend && cargo run --release ) &           # API on :7860
( cd frontend && flutter run -d chrome ) &        # Web on :8080

# Pre-deploy verify
( cd backend && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test )
( cd frontend && flutter analyze && flutter test && flutter build web --release )

# Deploy
git push origin main                                                 # → Cloudflare Pages auto-build
git subtree split --prefix=backend -b hf-backend                     # → split backend
git push <hf-remote> hf-backend:main --force                         # → HF Spaces rebuild

# Health
curl -s https://<hf-space>.hf.space/api/health | jq .
curl -s https://<hf-space>.hf.space/api/metrics | jq '.feed_health'
```
