#!/usr/bin/env bash
#
# mac-submit.sh — Upload the macOS .pkg + metadata to App Store Connect.
# Wraps `fastlane mac upload`. Same flow as iOS submit.sh but for macOS.
#
set -euo pipefail

cd "$(dirname "$0")/.."

PKG="${1:-./build/mac/TackMac.pkg}"

if [[ ! -f "$PKG" ]]; then
    echo "❌ Package not found at $PKG"
    echo "   Run scripts/mac-archive.sh first."
    exit 1
fi

if ! command -v fastlane >/dev/null 2>&1; then
    echo "❌ fastlane not installed. Try: brew install fastlane"
    exit 1
fi

echo "📤  Uploading macOS package to App Store Connect…"
fastlane mac upload \
    --pkg "$PKG" \
    --skip_binary_upload false \
    --skip_screenshots false \
    --skip_metadata false \
    --submit_for_review false \
    --automatic_release false

echo ""
echo "✅  Upload complete."
echo "    Confirm in App Store Connect → Tack for Mac → TestFlight / App Store versions."
