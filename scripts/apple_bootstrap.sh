#!/usr/bin/env bash
#
# apple_bootstrap.sh — the two things the App Store Connect API CANNOT do.
# Run this in YOUR terminal: it prompts for the Apple ID password + 2FA code.
#
#   1. Create App Group `group.app.tack.shared` and attach it to both bundle IDs
#      (no /v1/appGroups endpoint exists in the ASC API).
#   2. Create the "Tack" app record in App Store Connect
#      (POST /v1/apps → 403, the API only allows GET/UPDATE).
#
# Bundle IDs + provisioning profiles are ALREADY registered via the API.
#
set -euo pipefail
cd "$(dirname "$0")/.."

export FASTLANE_USER="${FASTLANE_USER:-valerosenrique@gmail.com}"
TEAM=KADHS6P8PY
GROUP=group.app.tack.shared

echo "▶ 1/4  App Group $GROUP"
fastlane produce group -u "$FASTLANE_USER" -b "$TEAM" -g "$GROUP" -n "Tack Shared"

echo "▶ 2/4  attach group → app.tack.ios"
fastlane produce associate_group -u "$FASTLANE_USER" -b "$TEAM" -a app.tack.ios "$GROUP"

echo "▶ 3/4  attach group → app.tack.ios.widget"
fastlane produce associate_group -u "$FASTLANE_USER" -b "$TEAM" -a app.tack.ios.widget "$GROUP"

echo "▶ 4/4  App Store Connect app record"
fastlane produce create \
  -u "$FASTLANE_USER" -b "$TEAM" \
  -a app.tack.ios \
  -q "Tack" \
  -y "tack-ios-1000" \
  -m en-US \
  -J ios \
  --skip_devcenter true \
  || echo "⚠️  If this says the name is taken, pick another (-q \"Tack Todo\") and re-run just this step."

echo
echo "✅ Done. Tell Claude to continue at Step 3 (archive)."
