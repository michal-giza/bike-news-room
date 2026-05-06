# Notifications (v1.1) — local + background fetcher

The push-notifications feature is **local-only** by design — no Firebase
project, no APNs key, no per-message billing, no third-party data flow.
Notifications are rendered by the OS via `flutter_local_notifications`;
the article-fetch heartbeat is driven by `workmanager`'s periodic-task
API, which delegates to Android's WorkManager and iOS's BGTaskScheduler.

This page covers:
1. The architecture and why we picked it.
2. Cadence + reliability tradeoffs vs. real push.
3. How to swap in a different transport (FCM, OneSignal) later if we
   need to without touching anything outside `lib/core/notifications/`.
4. Manual test steps on a real device.

---

## Architecture

```
PreferencesCubit                    (drives the toggle + per-discipline UI)
      │
      ▼
INotificationsService               (consent gating, topic-set state)
      │   ◄── single concrete impl: NotificationsService
      ▼
NotificationsProvider               (the swappable transport)
      │
      ├── LocalNotificationsProvider     ← v1.1 default
      │     • flutter_local_notifications  (rendering)
      │     • workmanager                  (periodic schedule)
      │
      ├── NoopNotificationsProvider       ← web / desktop / tests
      │
      └── (future) FcmNotificationsProvider, OneSignalProvider, etc.
```

The split between **service** and **provider** is the point: the
service handles consent gating, topic-set diffing, and persistence; the
provider does the platform-specific work. To switch transports later,
register a different provider in `lib/core/di/injection.dart` and
nothing else changes — no cubit edits, no Settings UI edits, no test
edits.

## Cadence + reliability

| Platform | Floor | Typical actual | Notes |
|---|---|---|---|
| Android (WorkManager periodic) | 15 min | 15–60 min | Doze / battery-saver may stretch. Foregrounded apps' tasks run more reliably. |
| iOS (BGTaskScheduler) | "occasional" | 2–6× / day | OS-decided; never on demand. Requires user to leave Background App Refresh on. |

This is fine for cycling news (2-min RTT to a fresh stage report doesn't
matter). It's **not** fine for live race-action push — if we ever ship
that as a v1.x feature, we plug in `FcmNotificationsProvider` and the
service stays unchanged.

## Cost model

Zero. Workmanager + flutter_local_notifications are free Flutter
plugins; Android's WorkManager and iOS's BGTaskScheduler are
OS-provided. No SDK quota to watch, no per-MAU billing to model.

The only marginal cost is a single GET per scheduled fire to our HF
Space backend (well within the free tier we already use for the
foreground feed).

## Privacy posture

Better than the FCM alternative:

- No Firebase project means no Google Cloud account dependency on the
  upload path, and no service-account key sitting in HF Space env vars.
- No advertising-id-adjacent data leaves the device. The FCM token
  (which is itself a stable per-install identifier) does not exist
  here.
- Play Data Safety form: under "Data shared with third parties" we now
  list **AdMob only**, not AdMob + Firebase Messaging.

## How to test on a real device

```bash
adb -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk
adb -s <serial> logcat -c
adb -s <serial> shell monkey -p com.majksquare.bike_news_room \
  -c android.intent.category.LAUNCHER 1
adb -s <serial> logcat | grep -i 'Notifications:'
```

The expected log line at boot (debug build only):

```
I/flutter: Notifications: ready (provider=local)
```

Then in the app: Settings → News alerts → toggle on → grant
POST_NOTIFICATIONS prompt → pick at least one discipline. The
Workmanager task is now scheduled.

To force-fire the task (for development; the OS won't schedule it for
~15 min on its own):

```bash
adb shell cmd jobscheduler run -f com.majksquare.bike_news_room 999
```

The bg dispatcher in `local_notifications_provider.dart` currently logs
"v1.1: noop placeholder" — v1.2 fills in the actual fetch + render.

## Adding a new transport later

Implement `NotificationsProvider`:

```dart
class FcmNotificationsProvider implements NotificationsProvider {
  @override String get name => 'fcm';
  @override Future<void> initialize() => /* Firebase.initializeApp() */;
  @override Future<bool> requestOsPermission() => /* … */;
  @override Future<void> schedulePeriodicCheck() async {
    // FCM is server-driven — no client-side schedule. Subscribe to a
    // server-managed topic instead, or no-op.
  }
  @override Future<void> subscribeToTopic(String t) =>
      FirebaseMessaging.instance.subscribeToTopic(t);
  @override Future<void> unsubscribeFromTopic(String t) =>
      FirebaseMessaging.instance.unsubscribeFromTopic(t);
  // … etc.
}
```

Then flip the DI line in `core/di/injection.dart`:

```diff
-      ? LocalNotificationsProvider()
+      ? FcmNotificationsProvider()
```

That's it. No service, cubit, UI, l10n, manifest, or test changes.

## Native config

Already wired in this repo:

- **Android**: `AndroidManifest.xml` declares `POST_NOTIFICATIONS`.
  WorkManager dependencies are pulled in automatically by the
  `workmanager` Flutter plugin's gradle module.
- **iOS**: `Info.plist` declares `BGTaskSchedulerPermittedIdentifiers`
  + `UIBackgroundModes` (`fetch`, `processing`). The user must also
  leave Settings → General → Background App Refresh ON for our app.

## Limitations to acknowledge in marketing

When we promote the news-alerts feature, be honest:

- Android: 15–60 min cadence depending on battery state.
- iOS: "a few times a day, decided by the OS"; turn on Background App
  Refresh in iPhone Settings.
- For live race notifications (within seconds), wait for v1.x.

The Settings page subtitle should reflect this once we draft v1.1
release notes — **don't ship copy that promises real-time push**.
