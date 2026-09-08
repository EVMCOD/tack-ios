#!/usr/bin/env bash
#
# archive.sh — Build a signed archive suitable for App Store Connect.
# Run before `submit.sh`.
#
# Requirements:
#   - xcpretty (optional; `gem install xcpretty`): pretty output
#   - Apple distribution certificate in your Keychain
#   - Provisioning profile for app.tack.ios (App Store)
#
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-Release}"
OUT_DIR="./build"
ARCHIVE="$OUT_DIR/Tack.xcarchive"
IPA="$OUT_DIR/Tack.ipa"

echo "🛠  Generating Xcode project"
xcodegen generate --quiet

echo "📦  Building archive (config=$CONFIG)…"
xcodebuild \
    -project Tack.xcodeproj \
    -scheme Tack \
    -configuration "$CONFIG" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE" \
    archive

echo "📦  Exporting IPA…"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$OUT_DIR" \
    -exportOptionsPlist "$OUT_DIR/exportOptions.plist"

if [[ ! -f "$IPA" ]]; then
    # gym names it Tack.ipa typically — fall back to whatever's in OUT_DIR
    IPA="$(ls -1 "$OUT_DIR"/*.ipa 2>/dev/null | head -1)"
fi

if [[ ! -f "$IPA" ]]; then
    echo "❌ IPA not produced"; exit 1
fi

echo "✅ Archive + IPA ready at:"
echo "     $ARCHIVE"
echo "     $IPA"
echo ""
echo "Next: scripts/submit.sh $IPA"
