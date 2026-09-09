#!/usr/bin/env bash
#
# mac-archive.sh — Build a signed .pkg for App Store distribution (macOS).
# Wraps `fastlane mac archive`. Output: ./build/mac/TackMac.pkg
#
# Requirements:
#   - macOS bundle `app.tack.macos` registered in Apple Developer
#   - `brew install fastlane`
#   - Distribution certificate in Keychain (Apple Distribution)
#
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v fastlane >/dev/null 2>&1; then
    echo "❌ fastlane not installed. Try: brew install fastlane"
    exit 1
fi

echo "🛠  Regenerating Xcode project"
xcodegen generate --quiet

echo "📦  Archiving TackMac for App Store…"
fastlane mac archive

PKG="$(pwd)/build/mac/TackMac.pkg"
if [[ ! -f "$PKG" ]]; then
    echo "❌ Package not produced"
    ls -la build/mac/ 2>/dev/null || true
    exit 1
fi

echo ""
echo "✅ Package ready at: $PKG"
echo "   Size: $(du -h "$PKG" | cut -f1)"
echo ""
echo "Next: scripts/mac-submit.sh"
