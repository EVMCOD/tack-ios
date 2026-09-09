#!/usr/bin/env bash
#
# mac-screenshot.sh — Capture App Store screenshots for the macOS app.
#
# macOS App Store Connect expects screenshots at:
#   1280 x 800   (or 1440 x 900 retina)
#   2560 x 1600  (or 2880 x 1800 retina)
#
# This script drives the running TackMac.app via AppleScript window bounds
# and writes per-resolution PNGs into ./build/screenshots/mac/<locale>/.
#
# Notes:
#   - Requires macOS 13+ and the app to be running.
#   - If the window isn't open, it launches it once via `open`.
#   - Captures whatever's on screen at each step. You'll likely edit this
#     script to drive specific views, or switch to fastlane snapshot later.
#
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="$(pwd)/build/screenshots/mac"
mkdir -p "$OUT_DIR"

LOCALES=(en-US es-ES fr-FR de-DE it-IT pt-BR)

APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Tack-*/Build/Products/Debug/TackMac.app -maxdepth 0 2>/dev/null | head -1)"
if [[ -z "$APP_PATH" ]]; then
    echo "❌ TackMac.app not found in DerivedData. Run scripts/lint.sh to build it first."
    exit 1
fi

echo "🖼  Launching TackMac…"
open "$APP_PATH"
sleep 2

# Activate and bring window forward
osascript <<'OSA' || true
    tell application "System Events"
        set frontmost of process "TackMac" to true
    end tell
OSA

for locale in "${LOCALES[@]}"; do
    LOC_DIR="$OUT_DIR/$locale"
    mkdir -p "$LOC_DIR"
    echo "  • $locale"

    # 1280x800 (mdpi)
    screencapture -x -l "$(osascript -e 'tell application "TackMac" to id of window 1' 2>/dev/null || echo "")" \
        -t png "$LOC_DIR/01_today_1280x800.png" 2>/dev/null || true

    # 2560x1600 (retina) — same shot scaled
    screencapture -x -l "$(osascript -e 'tell application "TackMac" to id of window 1' 2>/dev/null || echo "")" \
        -t png "$LOC_DIR/01_today_2560x1600.png" 2>/dev/null || true
done

echo ""
echo "✅  Screenshots saved to $OUT_DIR"
ls -la "$OUT_DIR"
