#!/usr/bin/env bash
# Capture a screenshot from the connected Galaxy S25 and save it to
# store-assets/screenshots/raw/. Usage: capture-screenshot.sh <name>.
set -euo pipefail

NAME="${1:?usage: capture-screenshot.sh <basename>}"
DEVICE="${DEVICE:-R3CYA05CHXB}"
OUT_DIR="$(cd "$(dirname "$0")/../store-assets/screenshots/raw" && pwd)"
OUT_PATH="$OUT_DIR/${NAME}.png"

adb -s "$DEVICE" exec-out screencap -p > "$OUT_PATH"

# Verify Android wrote a non-empty PNG (zero-byte file = capture failed
# silently, which has happened on cold-boot before).
SIZE=$(stat -f%z "$OUT_PATH" 2>/dev/null || stat -c%s "$OUT_PATH")
if [ "$SIZE" -lt 10000 ]; then
  echo "✗ ${NAME}.png is suspiciously small (${SIZE} bytes) — capture failed?"
  exit 1
fi
echo "✓ ${NAME}.png ($((SIZE / 1024)) KB)"
