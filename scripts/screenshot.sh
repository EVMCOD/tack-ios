#!/usr/bin/env bash
#
# screenshot.sh — Capture App Store screenshots via Fastlane snapshot.
# Boot the simulator, run the snapshot UI tests, dump PNGs per device + locale
# into ./build/screenshots/
#
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v fastlane >/dev/null 2>&1; then
    echo "❌ fastlane not installed. Try: brew install fastlane"
    exit 1
fi

# Ensure the project is regenerated so snapshots align with latest sources.
xcodegen generate --quiet

echo "📸  Capturing screenshots…"
fastlane ios screenshots

OUT="$(pwd)/build/screenshots"
if [[ -d "$OUT" ]]; then
    echo "✅  Screenshots saved to $OUT"
    ls -la "$OUT"
else
    echo "⚠️  No screenshots/ directory produced. Inspect fastlane output above."
fi
