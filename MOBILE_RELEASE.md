# Mobile release checklist — Bike News Room

End-to-end checklist for publishing the Flutter app to App Store + Play Store, with the four-layer ATT/UMP/Ads pattern already wired in source. **Don't skip steps** — most rejections come from one missing native flag.

Package id (both stores): `com.majksquare.bike_news_room`

---

## Phase 0 — Accounts & artefacts you have to create yourself

These are external accounts; nothing in the repo can do them for you.

- [ ] Apple Developer Program enrolment ($99/yr)
- [ ] Google Play Console one-time fee ($25)
- [ ] AdMob account, then in AdMob console: create app for iOS + Android,
      record real **App ID** (`ca-app-pub-XXXXXXX~YYYYYYY`)
- [ ] AdMob console: create three ad units per platform — Banner, Interstitial,
      Rewarded — record their full IDs (`ca-app-pub-XXXX/YYYY`)
- [ ] Firebase project — required if you want Analytics / Crashlytics; skippable
      otherwise. If you add it, place `google-services.json` at
      `frontend/android/app/` and `GoogleService-Info.plist` at
      `frontend/ios/Runner/`. Both are gitignored by default — **do not commit**.
- [ ] App Store Connect: create app record with bundle id
      `com.majksquare.bike_news_room`
- [ ] Play Console: create app with the same package name
- [ ] Hosted privacy policy URL — the [About → Privacy tab](frontend/lib/features/info/presentation/pages/info_page.dart)
      already has the content; mirror it to a Cloudflare Pages route at
      `https://bike-news-room.pages.dev/privacy` (one HTML file)
- [ ] Hosted terms URL at `https://bike-news-room.pages.dev/terms`
- [ ] Support email address (e.g. `hello@bike-news-room.pages.dev`)
- [ ] Marketing 1024×1024 icon (PNG, no alpha) for App Store listing —
      separate from the in-app icon

---

## Phase 1 — Replace placeholders in source

Search-and-replace the test IDs with your real ones:

| File | Find | Replace with |
|---|---|---|
| `frontend/ios/Runner/Info.plist` | `ca-app-pub-3940256099942544~1458002511` | iOS AdMob App ID |
| `frontend/android/app/src/main/AndroidManifest.xml` | `ca-app-pub-3940256099942544~3347511713` | Android AdMob App ID |
| `frontend/lib/core/ads/ad_config.dart` | empty `_iosProdBanner`, `_androidProdBanner`, `_iosProdInterstitial`, `_androidProdInterstitial` | real ad-unit IDs |
| `frontend/lib/core/ads/ad_config.dart` | `static const bool useProductionIds = false;` | `true` (only at production cutover, after the four IDs above are filled) |

Then verify nothing else hard-codes a `ca-app-pub-` string anywhere:

```sh
grep -r "ca-app-pub-" frontend/lib frontend/ios frontend/android
# Should match only AdConfig + Info.plist + AndroidManifest.
```

---

## Phase 2 — SKAdNetwork allowlist (iOS only)

`Info.plist` already contains a starter set of 54 `SKAdNetworkItems`. Apple
requires the current full list from Google. Update before submission:

1. Open https://developers.google.com/admob/ios/ios14#skadnetwork
2. Copy the full `SKAdNetworkItems` block
3. Replace the array in `frontend/ios/Runner/Info.plist`

If you forget this, install attribution breaks and CPMs drop 30–60% on iOS 14.5+.

---

## Phase 3 — Code signing

### iOS
1. In Xcode, open `frontend/ios/Runner.xcworkspace`
2. Select Runner target → Signing & Capabilities
3. Team: your Apple Developer team
4. Bundle id: `com.majksquare.bike_news_room`
5. Capabilities: add **Push Notifications** if you'll use FCM later
6. Build → Archive → Distribute → App Store Connect

### Android
1. Generate upload keystore:
   ```sh
   keytool -genkey -v -keystore ~/bike-news-room-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `frontend/android/key.properties` (gitignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/you/bike-news-room-upload.jks
   ```
3. Update `frontend/android/app/build.gradle.kts` `release` block:
   ```kotlin
   signingConfigs {
       create("release") {
           keyAlias = keystoreProperties["keyAlias"] as String
           keyPassword = keystoreProperties["keyPassword"] as String
           storeFile = file(keystoreProperties["storeFile"] as String)
           storePassword = keystoreProperties["storePassword"] as String
       }
   }
   buildTypes {
       release {
           signingConfig = signingConfigs.getByName("release")
       }
   }
   ```
4. Build: `flutter build appbundle --release`

---

## Phase 4 — Pre-ship verification checklist

Before tapping Submit, walk through every item. Each one has been the cause
of a real rejection in similar apps shipped using this skill.

### Native flags (Layer 1)
- [ ] `Info.plist`: `FIREBASE_ANALYTICS_COLLECTION_ENABLED = false` present
- [ ] `Info.plist`: `FirebaseCrashlyticsCollectionEnabled = false` present
- [ ] `Info.plist`: `GADDelayAppMeasurementInit = true` present
- [ ] `Info.plist`: all 4 `GOOGLE_ANALYTICS_DEFAULT_ALLOW_*` keys present and `false`
- [ ] `Info.plist`: `GADApplicationIdentifier` is the **production** AdMob app ID
- [ ] `Info.plist`: `NSUserTrackingUsageDescription` non-empty
- [ ] `Info.plist`: `SKAdNetworkItems` ≥ 46 entries from current Google list
- [ ] `PrivacyInfo.xcprivacy`: `NSPrivacyTracking = true` and tracking domains listed
- [ ] `AndroidManifest.xml`: all 7 deactivation `meta-data` keys present
- [ ] `AndroidManifest.xml`: `com.google.android.gms.permission.AD_ID` declared
- [ ] `AndroidManifest.xml`: `APPLICATION_ID` is the **production** AdMob app ID

### Boot sequence (Layers 2 + 3 + 4)
- [ ] `main.dart`: no `FirebaseAnalytics.instance.logEvent(...)` reachable from `main()`
- [ ] `main.dart`: `MobileAds.instance.initialize()` is **never** reachable
      from `main()` — only from `_initPostConsentServices()` or onboarding
- [ ] No widget calls `FirebaseAnalytics.instance` from a widget
      constructor or `initState()` of the first route
- [ ] `getIt<IAdService>` is registered (abstract) — never `getIt<AdMobService>`

### Onboarding flow
- [ ] ATT request fires on a screen that contains **only** the ATT prompt
      (Apple's native dialog is its own surface — the in-app screen behind
      it must be a clean transition)
- [ ] UMP request fires on the **next** screen, not the same one
- [ ] On iOS: ATT runs **before** UMP (the order is enforced by
      `OnboardingPage._runConsentFlowOnMobile` which awaits ATT first)
- [ ] Skipping ATT or denying it leaves the app fully functional with
      non-personalized ads (manually verify by tapping "Ask App Not to Track")

### AdConfig
- [ ] `AdConfig.useProductionIds = true`
- [ ] All four `_*ProdBanner` / `_*ProdInterstitial` constants are non-empty
- [ ] No hard-coded `ca-app-pub-…` outside `AdConfig` + native plists

### Store listings
- [ ] App icon present at `frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset`
- [ ] Adaptive icon present at `frontend/android/app/src/main/res/mipmap-*`
- [ ] Privacy questionnaire (App Store Connect): answered `Yes` to
      "Identifiers (Device ID)" with purpose **Third-Party Advertising**
- [ ] Data Safety section (Play Console): same answers
- [ ] Privacy URL points at the live hosted page
- [ ] Screenshots: 6 portrait + 6 landscape per device class
- [ ] Reviewer notes describe the ATT-then-UMP onboarding flow so the
      reviewer doesn't reject for "consent dialog appears too soon"

### Smoke tests on real hardware
- [ ] Cold start with no network: feed shows error state, no crash
- [ ] Cold start with airplane mode → toggle on: feed loads
- [ ] First-run onboarding: 3 steps → ATT prompt → UMP prompt → feed visible
- [ ] Tap "Ask App Not to Track" on ATT: app continues; banner ad shown is
      a non-personalized fallback (visually indistinguishable in test mode)
- [ ] Returning user (uninstall + reinstall = first-run): consent prompts
      reappear; otherwise normal launch skips them
- [ ] Settings → Privacy / Terms / About → opens long-form pages
- [ ] Settings → Redo onboarding: returns to first step, preserves bookmarks
- [ ] Settings → Export bookmarks: copies JSON to clipboard
- [ ] Subscribe to digest, click confirm link in email: confirmation page renders
- [ ] Live ticker bar appears and rotates entries when backend has data
- [ ] Share article via native share sheet (mobile only)

---

## Phase 5 — Submission cadence

1. Submit the iOS build to TestFlight first; install on at least 2 real devices
   for 24h to catch background-task surprises
2. Submit the Android build as **internal test** in Play Console; same 24h
3. Promote both to production simultaneously so users on both stores see
   updates land at the same time

If Apple rejects the first submission, 95% of the time it's:
- ATT prompt appearing before the user has any sense of what the app does → onboarding sequence is wrong
- Privacy manifest missing `NSPrivacyTracking = true` → see `PrivacyInfo.xcprivacy`
- AdMob initializing before ATT → grep `MobileAds.instance.initialize` and verify the call site is reachable only via `_initPostConsentServices`

---

## What's intentionally NOT done in source yet

These need real account credentials before they make sense in code; the
skill calls them out as "uncomment the Firebase block when ready":

- Firebase Core / Analytics / Crashlytics SDKs — flags are in place; add
  the SDK + uncomment the marked blocks in `main.dart` + `onboarding_page.dart`
  once the Firebase project exists
- Push notifications — wait until daily-active-users justifies the engineering

Both of those will reuse the same four-layer pattern; nothing about the
existing flow needs to change to add them.
