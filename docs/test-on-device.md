# Testing Bike News Room on a real device

The web build runs against the live HF Space because Cloudflare Pages bakes
the API URL in at build time. Mobile builds default to `https://michal-giza-bike-news-room.hf.space`
(see `frontend/lib/core/network/api_client.dart`) so a plain `flutter run`
also "just works" — but if you ever pass `--dart-define=API_BASE_URL=...`
yourself, that override wins.

The integration suite logs the resolved API URL on every boot:

```
I/flutter (29922): [ApiClient] API_BASE_URL=https://michal-giza-bike-news-room.hf.space
```

If you see `localhost` or any non-prod URL on a physical device, the device
cannot reach the backend and every screen will be empty. Re-install the app
without an `API_BASE_URL` override (or pass the right one explicitly).

---

## Quick "just give me a working app on this phone"

```bash
adb devices                       # confirm phone is connected
cd frontend
flutter run -d <device-serial>    # debug, prod backend baked in
```

That's it. The default in `api_client.dart` points at the live HF Space,
so no flags are needed.

---

## Local backend dev

Want to point the phone at your laptop's running backend? The phone can't
resolve `localhost` to your machine. Use:

| Phone type | URL |
|---|---|
| Android emulator | `--dart-define=API_BASE_URL=http://10.0.2.2:7860` |
| Physical Android | `--dart-define=API_BASE_URL=http://<your-lan-ip>:7860` |
| iOS simulator | `--dart-define=API_BASE_URL=http://localhost:7860` |
| Physical iPhone | `--dart-define=API_BASE_URL=http://<your-lan-ip>:7860` |

Find your LAN IP:

```bash
ipconfig getifaddr en0    # macOS
hostname -I | awk '{print $1}'  # Linux
```

Then both phone and laptop must be on the same Wi-Fi, and the backend has
to listen on `0.0.0.0:7860` (not just `127.0.0.1`).

---

## Running the integration suite on a device

```bash
adb devices                                      # find <serial>
cd frontend
flutter test integration_test/app_test.dart \
  --device-id <serial>
```

Takes ~10 minutes for the full 45-test suite. Failures dump the
RenderFlex/exception trace inline; jump to the test name for the repro.

### Live-backend smoke (opt-in)

Asserts the production HF Space is reachable + returns articles +
the `region=poland` filter actually works against real data:

```bash
flutter test integration_test/live_backend_test.dart \
  --device-id <serial> \
  --dart-define=BNR_LIVE_BACKEND=true
```

Without `BNR_LIVE_BACKEND=true` the file is a no-op — keeps CI deterministic.

---

## Debugging "I see no articles on the device"

Single most common cause: the APK on the device was built without the
correct `API_BASE_URL`. Check:

```bash
adb logcat | grep ApiClient
```

If the line says anything other than the live HF URL (or your local dev
backend), wipe and reinstall:

```bash
adb uninstall com.majksquare.bike_news_room
flutter run -d <serial>
```

If the URL is correct but the feed is still empty:

1. Hit the URL directly to confirm the backend is up:
   ```bash
   curl -s "https://michal-giza-bike-news-room.hf.space/api/health"
   ```
   Should return `{"status":"ok"}`. If the HF Space is cold, expect
   a 10–30 s delay on the first request — the live-backend smoke test
   accounts for this with a generous timeout.

2. Confirm articles exist for your filter:
   ```bash
   curl -s "https://michal-giza-bike-news-room.hf.space/api/articles?region=poland&limit=5"
   ```

3. If the backend is fine but the app is empty, force-stop + clear data:
   ```bash
   adb shell am force-stop com.majksquare.bike_news_room
   adb shell pm clear com.majksquare.bike_news_room
   ```

---

## Building a signed release APK for sideload

```bash
./scripts/build-android-release.sh
adb install -r frontend/build/app/outputs/flutter-apk/app-release.apk
```

This is a Play-Console-signed build (release keys via `key.properties`)
running against the production backend. Use it for QA before uploading
the `.aab` to Play. See `docs/play-store-release.md` for the full release
flow.
