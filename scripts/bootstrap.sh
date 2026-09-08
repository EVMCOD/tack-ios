#!/usr/bin/env bash
# Bootstrap a fresh dev environment for Tack.
# Assumes xcodegen (brew install xcodegen), Xcode 15.4+, and macOS.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "🧭 Tack bootstrap"
echo "=================="

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "→ xcodegen missing. Installing via Homebrew…"
    brew install xcodegen
  else
    echo "✗ Homebrew not found. Install xcodegen manually: https://github.com/yonaskolb/XcodeGen"
    exit 1
  fi
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "✗ Xcode not found. Install from the App Store."
  exit 1
fi

echo "→ Generating Xcode project from project.yml…"
xcodegen generate --quiet

echo "→ Resolving SwiftPM packages (none yet)…"
echo "→ Building Tack for iOS Simulator (Debug)…"
xcodebuild \
  -project Tack.xcodeproj \
  -scheme Tack \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -configuration Debug \
  build \
  | tail -30 || { echo "✗ Build failed — see output above"; exit 1; }

echo ""
echo "✓ Tack ready. Open Tack.xcodeproj to start."
echo "  Run UI tests:  ./scripts/test.sh"
echo "  Build script:  ./scripts/build.sh"
