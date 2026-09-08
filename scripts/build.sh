#!/usr/bin/env bash
# Build Tack. Usage: ./scripts/build.sh [Debug|Release] [simulator name]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Debug}"
DEST="${2:-iPhone 15 Pro}"

xcodegen generate --quiet
xcodebuild \
  -project Tack.xcodeproj \
  -scheme Tack \
  -destination "platform=iOS Simulator,name=${DEST}" \
  -configuration "${CONFIG}" \
  build
