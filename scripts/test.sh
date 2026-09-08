#!/usr/bin/env bash
# Run UI tests in the iOS Simulator.
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate --quiet
xcodebuild \
  -project Tack.xcodeproj \
  -scheme Tack \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
  -configuration Debug \
  test
