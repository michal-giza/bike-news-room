# Bike News Room — Google Play release guide

End-to-end recipe for taking the current main branch from local clone to a
public Google Play listing. Follow it once, top to bottom; subsequent
releases drop straight to step 6.

---

## 0. One-time prerequisites

| Item | What you need |
|---|---|
| Google Play Developer account | $25 lifetime fee, register at https://play.google.com/console/ |
| App Bundle Signing | Use Play App Signing (Google manages the app key, you keep the upload key). Default since 2021. |
| Java JDK 17 | `brew install openjdk@17` (already required for Gradle) |
| Privacy policy URL | A publicly hosted URL describing data collection. Required by Play. See §3 below. |

---

## 1. Generate the upload keystore (one time)

The upload key is what you sign every AAB with before uploading. It is **not**
the app signing key — Google holds that one and re-signs your AAB at
distribution time. Lose this upload key and you can rotate it via Play
Console; lose the *app* signing key (only relevant if you opt out of
Play App Signing) and your app is bricked forever.

```bash
cd frontend
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storetype JKS
```

Answer the prompts (CN can be your name, OU/O can be Bike News Room, country PL).
Pick a strong password and **back the .jks file up offline** — Dropbox + a
hardware key, or 1Password file attachment.

Then create `frontend/android/key.properties` (already gitignored):

```properties
storeFile=app/upload-keystore.jks
storePassword=<the password you just set>
keyAlias=upload
keyPassword=<same password unless you set a different key password>
```

Verify the file is ignored:

```bash
git status | grep key.properties   # should print nothing
```

---

## 2. Bump the version

`frontend/pubspec.yaml`:

```yaml
version: 0.1.0+1
#         ^   ^
#         |   versionCode (Play increments mandatorily on every upload)
#         versionName (semver, what users see)
```

Each Play upload **must** have a higher `versionCode` than every previously
uploaded AAB — even rejected ones. Bump it before every release build.

---

## 3. Privacy policy

Play requires a hosted, publicly accessible privacy policy URL for any app
that handles personal data — and we do (anonymous analytics consent flows
through ATT/UMP, AdMob requests device identifiers post-consent).

Easiest hosting: a static page on Cloudflare Pages alongside the existing
web build. Drop the file at `frontend/web/privacy.html` and it ships at
`https://bike-news-room.pages.dev/privacy`. Minimum content:

- What data we collect (article views/bookmarks stored locally; AdMob
  collects device ID + ad-related signals only after explicit consent; no
  account, no email, no location).
- Where data goes (HF Space backend stores no PII; AdMob sees consented
  signals only; no third-party analytics).
- Contact email for privacy requests.
- Last-updated date.

The URL goes in Play Console → App content → Privacy policy.

---

## 4. Prepare Play Console listing assets

### Required graphics

| Asset | Spec | Notes |
|---|---|---|
| App icon | 512×512 PNG, 32-bit, no transparency | Already at `frontend/web/icons/Icon-512.png`. |
| Feature graphic | 1024×500 PNG/JPEG | Create from `web/icons/Icon-512.png` on a `#0E0F11` tile + the wordmark "Bike News Room" + tagline. |
| Phone screenshots | min 2, max 8. 1080×1920 (or any 16:9 / 9:16) | Capture from the live device feed, calendar, settings, dark + light variants. |
| 7-inch tablet screenshots | optional but recommended | Same content, landscape. |
| 10-inch tablet screenshots | optional | Same content, landscape. |

Capture script for the device:

```bash
adb shell screencap -p /sdcard/screen.png && \
  adb pull /sdcard/screen.png screenshots/feed.png
```

### Listing copy

Drop these into Play Console → Main store listing.

**Short description** (≤80 chars):
> Cycling news from around the world — road, MTB, gravel, track, refreshed every 30 min.

**Full description** (≤4000 chars):
> Bike News Room is a clean, ad-light cycling news aggregator. We pull stories from publishers across road racing, MTB, gravel, cyclocross, track, and BMX, deduplicate them, and refresh every 30 minutes — so you see what matters in one feed instead of bouncing between ten sites.
>
> What it does:
> • Live feed of cycling news from publishers worldwide — UCI WorldTour, Pro Continental, mountain biking, gravel, track.
> • Filter by region (World, Europe, Poland, Spain) or discipline (Road, MTB, Gravel, CX, Track, BMX).
> • Race calendar with upcoming editions of Tours, Monuments, Worlds, and Olympics.
> • Bookmark anything for later — survives backend retention sweeps.
> • Source-add: paste any RSS URL and we'll add it to the catalogue if it's a real cycling source.
> • 9 languages: English, Polish, Spanish, French, Italian, German, Dutch, Portuguese, Japanese.
> • Privacy-respecting: no account, no email, no tracking before consent.
>
> Built by a cyclist for cyclists. No login, no paywall, no algorithm tuning to keep you scrolling.

**Categorization:**
- App category: News & Magazines (or Sports — News & Magazines fits aggregator better)
- Tags: Cycling, Sports News, RSS Reader, Aggregator

**Contact details:**
- Website: https://bike-news-room.pages.dev/
- Email: msquaregiza@gmail.com (or a dedicated support@)
- Phone: optional

### Content rating questionnaire

Answer the IARC questionnaire at App content → Content rating. Expected
result for an aggregator with no UGC, no chat, no purchases: **PEGI 3 / ESRB Everyone**.

| Question | Answer |
|---|---|
| Violence | None |
| Sex / nudity | None |
| Profanity | None (UGC: aggregated, but RSS publishers don't typically swear in headlines — answer "Possibly, in linked content") |
| Drugs / alcohol / tobacco | None |
| Gambling / simulated gambling | None |
| User interaction (chat, social) | No |
| Shares user location | No |
| Allows in-app purchases | No |

### Data safety form

Required since 2022. Answer at App content → Data safety:

- **Data types collected:** Device or other IDs (yes — for AdMob personalization, only after consent).
- **Purpose:** Advertising or marketing.
- **User can opt out:** Yes (UMP consent form on first launch + iOS App Tracking Transparency).
- **Data shared with third parties:** Yes — AdMob (Google).
- **Encryption in transit:** Yes (HTTPS only; CSP enforced; no cleartext).
- **Data deletion request:** Email msquaregiza@gmail.com — explain we hold no PII so deletion is a no-op for our backend; AdMob requests handled via Google's process.

### Target audience

App content → Target audience and content. Tick **18+** because of the
ads (AdMob personalisation requires adult audience under Play's "Designed
for Families" policy distinction). Confirm: "Does not target children."

---

## 5. Build the AAB

```bash
./scripts/build-android-release.sh
```

The script:
1. Verifies `android/key.properties` exists (loud fail if not).
2. Runs `flutter clean` + `pub get`.
3. Builds `app-release.aab` and `app-release.apk` with:
   - `--dart-define=API_BASE_URL=https://michal-giza-bike-news-room.hf.space`
     (so the device can reach the live backend — without this, the APK
     defaults to localhost:7860 and the feed is empty)
   - `--obfuscate --split-debug-info=build/app/outputs/symbols`
     (saves ~2 MB and protects against trivial reverse-engineering)
4. Prints sha256 + size of both artifacts.

Outputs:
- `frontend/build/app/outputs/bundle/release/app-release.aab` — upload this.
- `frontend/build/app/outputs/flutter-apk/app-release.apk` — sideload for QA.
- `frontend/build/app/outputs/symbols/` — keep alongside the AAB; Play's
  crash reporter needs these to deobfuscate stack traces.

---

## 6. Verify the AAB before uploading

Sideload the corresponding APK to a physical device and run through the
QA checklist before every Play upload. The integration suite covers most
of this on the test device but the AAB is signed differently and uses
a release Dart snapshot — bugs that don't appear in debug builds *can*
appear here.

```bash
adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk
```

QA checklist:
1. Cold launch shows the splash (brand mark on `#0E0F11`), then onboarding
   if first run, else feed.
2. **Articles render.** No "no articles match filter criteria" empty state
   on a fresh install. (This was the localhost-default bug — guarded by
   `test/core/network/api_client_test.dart`.)
3. Pick Polish in onboarding → feed shows Polish articles only.
4. Top bar shows brand mark + wordmark, no system status icons overlap
   the title.
5. Tap each bottom-nav tab — feed / following / search / calendar /
   bookmarks all open without crashing.
6. Open SettingsPage → switch theme → confirm persists across an
   app-restart.
7. Long-press home + clear from recents + cold launch again → no
   data loss (theme + language + onboarding-complete persist).
8. Run integration suite once on the live backend:
   ```bash
   flutter test integration_test/live_backend_test.dart \
     --device-id <serial> \
     --dart-define=BNR_LIVE_BACKEND=true
   ```

If anything in 1-8 fails, **do not upload**.

---

## 7. Upload to Play Console

1. Play Console → Bike News Room → Release → **Internal testing** (start
   here for the first release; promote to Production after a 1-week
   internal soak). Create a new release.
2. Upload `app-release.aab`. Play extracts version code + name automatically.
3. Upload `app-release.symbols.zip` to "App symbols" if prompted.
4. Add release notes (≤500 chars per locale). Example for first release:
   > Initial release. Cycling news aggregator with 30-minute refresh,
   > 9 languages, region + discipline filters, race calendar, and
   > local bookmarks. Bug reports: msquaregiza@gmail.com.
5. Review → Save → Send for review.

First-time review takes 1–7 days. Subsequent releases are usually
≤24 hours.

---

## 8. Post-launch

- **Crash reports** appear at Play Console → Quality → Android vitals →
  Crashes & ANRs. Resolve before they affect ≥1% of sessions.
- **Pre-launch reports** (Play runs your app on a few real devices for ~5
  minutes and reports crashes / accessibility issues) appear under
  Quality → Pre-launch report.
- **Keep `android/app/upload-keystore.jks` backed up.** If you lose it
  you can request a Play key reset, but it takes days and is an outage.
- **Bump versionCode + versionName before every upload.** The script
  does NOT do this automatically — keep it manual so each release is
  a deliberate decision.

---

## Reference: directory layout this guide creates

```
frontend/
├── android/
│   ├── key.properties               # gitignored, you create this
│   └── app/
│       └── upload-keystore.jks      # gitignored, keytool creates this
├── build/
│   └── app/outputs/
│       ├── bundle/release/app-release.aab    # upload this to Play
│       ├── flutter-apk/app-release.apk       # sideload for QA
│       └── symbols/                          # crash deobfuscation
└── web/
    └── privacy.html                  # privacy policy, ships with web
docs/
└── play-store-release.md             # this file
scripts/
└── build-android-release.sh          # one-shot AAB + APK build
```
