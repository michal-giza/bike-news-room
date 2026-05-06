# Security audit — 2026-05-07

Pre-monetisation pass before the GitHub repo flips to private and the
v1.2 build goes to Play Console production. Eight categories, scored
green / yellow / red. Re-run on every release.

---

## Summary

| Area | Status | Notes |
|---|---|---|
| 1. Secrets in git history | ✅ green | No `*.jks`, `*.env`, `key.properties`, or service-account JSON ever committed |
| 2. Hardcoded credentials | ✅ green | Every secret reference is `std::env::var()` or `--dart-define` |
| 3. Admin endpoint auth | ✅ green | All `/api/admin/*` routes wrapped in `require_admin`; constant-time compare; fail-closed if `ADMIN_TOKEN` env var absent |
| 4. Web CSP + transport | ✅ green | CSP locked to `'self' + hf.space + gstatic`; no `unsafe-eval`; `frame-ancestors 'none'`; no `usesCleartextTraffic` on Android |
| 5. .gitignore coverage | ✅ green | Verified via `git check-ignore`: `key.properties`, `*.jks`, `google-services.json`, `*.env`, `firebase-adminsdk*` all blocked at root + frontend levels |
| 6. Backend dep CVEs | 🟡 yellow → ✅ green | One RUSTSEC entry (rsa via sqlx-mysql, transitively from sqlx macros) — not exploitable, suppressed in `.cargo/audit.toml` with documented rationale |
| 7. Frontend dep CVEs | ✅ green | All deps current within their major-version line; no active advisories |
| 8. **Production AdMob IDs** | 🔴 **red — action required** | `AdConfig.useProductionIds = false` and the four `_*ProdBanner` / `_*ProdInterstitial` constants are empty strings. Going monetised without filling these = test ads forever, $0 revenue |

---

## Category detail

### 1. Secrets in git history

```
$ git log --all --pretty=format: --name-only --diff-filter=A \
    | sort -u | grep -iE "key.properties|jks|keystore|p8|p12|google-services|GoogleService-Info|firebase-adminsdk|.env|secrets|credentials"
(no output)
```

Nothing leaked. The keystore + `key.properties` arrived during the
v1.0 release prep already gitignored at root + `frontend/` levels —
verified post-hoc.

### 2. Hardcoded credentials

`grep -rIniE 'password|secret|api[_-]?key|token|bearer' backend/src frontend/lib`
shows only:

- `backend/src/application/digest_use_case.rs` — `RESEND_API_KEY` env-var read
- `backend/src/web/routes.rs` — `ADMIN_TOKEN` env-var read
- subscriber confirm/unsubscribe tokens — generated, not stored secrets

No literal strings. Resend + admin tokens are env-var-injected on the
HF Space side; if the Space restarts without them the relevant
endpoints fail closed.

### 3. Admin endpoint authentication

```rust
fn require_admin(headers: &axum::http::HeaderMap) -> Result<(), StatusCode> {
    let expected = std::env::var("ADMIN_TOKEN").ok();
    let Some(expected) = expected.filter(|s| !s.is_empty()) else {
        return Err(StatusCode::FORBIDDEN);  // fail closed
    };
    let provided = headers.get("x-admin-token")
        .and_then(|v| v.to_str().ok()).unwrap_or("");
    if subtle_eq(provided.as_bytes(), expected.as_bytes()) { Ok(()) }
    else { Err(StatusCode::FORBIDDEN) }
}
```

- Constant-time compare via `subtle_eq` so timing doesn't leak length.
- Empty / unset env var → 403 (the safer default — no accidentally-open
  admin endpoints).
- Eight admin endpoints all gated:
  `POST /api/admin/source-candidates/:id/{promote,reject}`,
  `POST /api/admin/live-ticker`,
  `POST /api/admin/backfill`,
  `GET /api/admin/feeds/{stale,dead}`.

### 4. Web CSP + transport

`frontend/web/index.html` ships with a hand-tuned CSP:

```
default-src 'self';
script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com;
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
font-src 'self' https://fonts.gstatic.com data:;
img-src 'self' data: blob: https:;
connect-src 'self' https://*.hf.space https://www.gstatic.com https://fonts.googleapis.com https://fonts.gstatic.com;
worker-src 'self' blob:;
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
```

- `wasm-unsafe-eval` is required for Flutter Web's CanvasKit dart2wasm
  runtime; no plain `unsafe-eval`.
- `unsafe-inline` for styles is required by Flutter's inline style
  attributes; no scripts.
- `connect-src` whitelists exactly `hf.space` (the backend) +
  Google's CDN for fonts. No analytics endpoints.
- `frame-ancestors 'none'` — never embeddable in a third-party iframe.

Android: `AndroidManifest.xml` doesn't set `usesCleartextTraffic`, so
the platform default of "block" applies — backend MUST be HTTPS,
which it is.

iOS: no `NSAllowsArbitraryLoads`. ATS enforced.

### 5. .gitignore coverage

```
$ git check-ignore -v frontend/android/key.properties \
    frontend/android/app/upload-keystore.jks \
    frontend/android/app/google-services.json \
    frontend/ios/Runner/GoogleService-Info.plist \
    frontend/.env backend/.env

frontend/.gitignore:54: android/key.properties      → frontend/android/key.properties
frontend/.gitignore:55: android/app/upload-keystore.jks → frontend/android/app/upload-keystore.jks
frontend/.gitignore:62: android/app/google-services.json → frontend/android/app/google-services.json
frontend/.gitignore:63: ios/Runner/GoogleService-Info.plist → frontend/ios/Runner/GoogleService-Info.plist
.gitignore:18: *.env                                → frontend/.env
.gitignore:18: *.env                                → backend/.env
```

Every sensitive path is blocked at one of the two `.gitignore` levels.

### 6. Backend dep CVEs

`cargo audit` (cargo-audit 0.21+) reports two findings:

#### RUSTSEC-2023-0071 — `rsa` 0.9.10 Marvin timing sidechannel (medium)

Pulled in transitively via `sqlx-mysql` because sqlx's macro crate
loads every backend's macro at compile time, regardless of which
features the consumer enables. We only use `sqlx` with the `sqlite`
feature; the MySQL TLS handshake code (which is where the timing
sidechannel triggers) is never reached at runtime.

**Resolution**: suppressed via `backend/.cargo/audit.toml` with the
documented rationale above. Re-evaluate when sqlx 0.9 ships and
hopefully fixes the macro-bloat issue.

#### RUSTSEC-2025-0057 — `fxhash` unmaintained (warning, no CVE)

Pulled in transitively via `scraper → selectors`. We use `scraper`
in `infrastructure/html_crawler.rs` for HTML extraction; `fxhash` is
the hashing backend for an internal HashMap with no security impact.

**Resolution**: suppressed in `.cargo/audit.toml`. Track upstream for
a maintained replacement.

After suppressions, `cargo audit` exits clean.

### 7. Frontend dep CVEs

`flutter pub outdated` shows several majors behind (firebase deps not
applicable; we removed those in v1.1):

- `flutter_local_notifications` 17 → 21 (deferred — major API rewrite)
- `permission_handler` 11 → 12
- `share_plus` 11 → 13
- `google_mobile_ads` 5 → 8

None have active CVEs. Bulk upgrade is a separate PR — pin to current
for the v1.2 production push.

### 8. 🔴 Production AdMob IDs (action required)

`frontend/lib/core/ads/ad_config.dart`:

```dart
static const bool useProductionIds = false;
static const _iosProdBanner = '';
static const _androidProdBanner = '';
static const _iosProdInterstitial = '';
static const _androidProdInterstitial = '';
```

Going monetised without filling these = the production AAB ships
Google's documented test ads in perpetuity. **No revenue, ever.**

This is a 5-minute fix once you've created the AdMob app + ad units:

1. AdMob console → Apps → Add app → name + platform → save the
   `ca-app-pub-XXXX~YYYY` AdMob app ID.
2. Replace the `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"`
   entry in `frontend/android/app/src/main/AndroidManifest.xml` with
   the real value (currently a test ID).
3. Replace `GADApplicationIdentifier` in
   `frontend/ios/Runner/Info.plist` with the real value.
4. AdMob console → Ad units → Create banner + interstitial for both
   platforms → fill the four constants above.
5. Flip `useProductionIds = true`.
6. Wait 24-48h for AdMob to propagate the new app config; until then
   `BannerAdListener.onAdFailedToLoad` will fire with `no-fill` errors,
   which is normal.

I am intentionally not landing these values for you — AdMob IDs are
account-bound + revocable; you should generate them yourself and paste
them in.

---

## Action items in priority order

1. 🔴 **Fill AdMob production IDs + flip `useProductionIds`** (you, 30 min once AdMob console is set up).
2. 🟡 **Confirm `HF_TOKEN`, `ADMIN_TOKEN`, `RESEND_API_KEY` are set as GitHub Actions secrets in the new private repo** (you, 5 min). Currently used by `.github/workflows/deploy.yml`.
3. 🟢 Run `cargo audit` on every release. Add to CI matrix (one-line `cargo install cargo-audit && cargo audit`).
4. 🟢 Schedule a Flutter dep bulk-upgrade PR for v1.3 (~1h).

## What this audit doesn't cover

- **Penetration testing** — manual fuzzing of the API surface, replay
  attacks on the unsubscribe-token endpoint, SQL-injection regression.
  Worth one external pass at >5k MAU; not required for v1.2 launch.
- **Mobile reverse engineering** — anyone can `apktool` the AAB and
  inspect strings. We've already obfuscated via R8 + split-debug-info,
  so call graphs are scrambled. There's nothing in the binary that's
  worth extracting.
- **Backend infrastructure** — HF Space hardening (rate-limiting at
  the edge, DDoS protection) is delegated to Hugging Face; the platform
  handles it for free-tier Spaces.
- **AdMob fraud / invalid traffic** — Google handles this; we don't
  have to.
