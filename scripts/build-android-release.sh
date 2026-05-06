#!/usr/bin/env bash
# Build a Play-Console-ready Android App Bundle.
#
# Why a script and not raw `flutter build`:
#   - bakes the production API_BASE_URL via --dart-define, otherwise
#     the APK defaults to localhost:7860 and the device can't reach
#     any backend (real bug we hit before — see commit 715ee4d).
#   - runs `flutter clean` first so a stale debug build doesn't poison
#     the obfuscation map.
#   - emits both an .aab (Play upload format) and a fat .apk for
#     internal/local distribution.
#   - prints sha256 + bundle size at the end so you can verify the
#     uploaded artifact matches what you tested.
#
# Prereqs (one-time):
#   1. android/key.properties exists with storeFile=, storePassword=,
#      keyAlias=, keyPassword= — see docs/play-store-release.md.
#   2. The keystore .jks file lives at the path key.properties points
#      at (typically android/app/upload-keystore.jks).
#
# Usage:
#   ./scripts/build-android-release.sh [API_BASE_URL]
#
#   No arg → uses the live HF Space (`https://michal-giza-bike-news-room.hf.space`).
#   Pass an arg to override (staging environment, custom backend, etc).

set -euo pipefail

API_BASE_URL="${1:-https://michal-giza-bike-news-room.hf.space}"

cd "$(dirname "$0")/../frontend"

echo "▶ Verifying release-signing config"
if [ ! -f "android/key.properties" ]; then
  echo "✗ android/key.properties is missing — see docs/play-store-release.md"
  exit 1
fi

echo "▶ Cleaning previous build artifacts"
flutter clean
flutter pub get

echo "▶ Building Android App Bundle (.aab) for Play Console"
echo "    API_BASE_URL=${API_BASE_URL}"
flutter build appbundle \
  --release \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --no-tree-shake-icons

echo "▶ Building fat APK for sideload / internal QA"
flutter build apk \
  --release \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --no-tree-shake-icons

AAB="build/app/outputs/bundle/release/app-release.aab"
APK="build/app/outputs/flutter-apk/app-release.apk"

echo
echo "▶ Build complete"
echo
echo "    AAB → ${AAB}"
echo "        size:   $(du -h "${AAB}" | awk '{print $1}')"
echo "        sha256: $(shasum -a 256 "${AAB}" | awk '{print $1}')"
echo
echo "    APK → ${APK}"
echo "        size:   $(du -h "${APK}" | awk '{print $1}')"
echo "        sha256: $(shasum -a 256 "${APK}" | awk '{print $1}')"
echo
echo "Next steps:"
echo "  1. Upload the .aab to Play Console → Release → Production / Internal testing."
echo "  2. Keep build/app/outputs/symbols/ — Play needs it to deobfuscate crashes."
echo "  3. Sideload-test the .apk on a physical device:"
echo "       adb install -r ${APK}"
