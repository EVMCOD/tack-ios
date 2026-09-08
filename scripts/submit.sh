#!/usr/bin/env bash
#
# submit.sh — Upload a signed IPA + metadata to App Store Connect.
#
# Wrapper around fastlane deliver (already configured in fastlane/Fastfile).
# For a fully scripted end-to-end:  fastlane ios ship
#
set -euo pipefail

cd "$(dirname "$0")/.."

IPA="${1:-./build/Tack.ipa}"

if [[ ! -f "$IPA" ]]; then
    echo "❌ IPA not found at $IPA"
    echo "   Run scripts/archive.sh first."
    exit 1
fi

if ! command -v fastlane >/dev/null 2>&1; then
    echo "❌ fastlane not installed. Try: brew install fastlane"
    exit 1
fi

echo "📤  Uploading to App Store Connect…"
fastlane ios upload \
    --ipa "$IPA" \
    --skip_binary_upload false \
    --skip_screenshots false \
    --skip_metadata false \
    --submit_for_review false \
    --automatic_release false

echo ""
echo "✅  Upload complete."
echo "    Confirm in App Store Connect → Tack → TestFlight / App Store versions."
