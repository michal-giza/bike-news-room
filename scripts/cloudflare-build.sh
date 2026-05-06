#!/usr/bin/env bash
#
# Cloudflare Pages build script for the Flutter Web frontend.
#
# Cloudflare's default build image doesn't ship with Flutter, so we install a
# pinned channel into a scratch dir and run `flutter build web --release`.
# The result lands in `frontend/build/web` — point CF Pages' "build output
# directory" setting at that path.
#
# Required CF Pages environment variables:
#   API_BASE_URL       e.g. https://michal-giza-bike-news-room.hf.space
#   FLUTTER_VERSION    e.g. 3.41.7   (optional; defaults to stable)
#
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.7}"
API_BASE_URL="${API_BASE_URL:-https://michal-giza-bike-news-room.hf.space}"

echo "▶ Installing Flutter ${FLUTTER_VERSION}"
if [ ! -d "_flutter" ]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git _flutter
fi
export PATH="$PWD/_flutter/bin:$PATH"
flutter --version

echo "▶ Resolving Flutter dependencies"
flutter config --no-analytics
flutter pub get -C frontend

echo "▶ Building web release with API_BASE_URL=${API_BASE_URL}"
cd frontend
flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --no-tree-shake-icons

echo "▶ Build complete — output: frontend/build/web"
ls -la build/web | head -10
