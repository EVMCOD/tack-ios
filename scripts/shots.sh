#!/usr/bin/env bash
#
# shots.sh — App Store screenshots on a 6.9" iPhone (1320×2868), all locales.
#
# Runs ScreenshotTests on a freshly erased simulator so the status bar carries
# no "◄ PreviousApp" breadcrumb, then pulls the PNGs out of the .xcresult.
#
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-iPhone 17 Pro Max}"
OUT="build/screenshots"
LOCALES=("en:en_US:en-US" "es:es_ES:es-ES" "fr:fr_FR:fr-FR" "de:de_DE:de-DE" "it:it_IT:it-IT" "pt-BR:pt_BR:pt-BR")
[[ $# -gt 0 ]] && LOCALES=("$@")

UDID="$(xcrun simctl list devices available -j | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
for rt,devs in d.items():
    for x in devs:
        if x['name']=='$DEVICE': print(x['udid']); raise SystemExit
")"
[[ -z "$UDID" ]] && { echo "❌ simulator '$DEVICE' not found"; exit 1; }
echo "📱 $DEVICE  $UDID"

for entry in "${LOCALES[@]}"; do
    LANG_CODE="${entry%%:*}"; rest="${entry#*:}"
    LOCALE="${rest%%:*}"; DIR="${rest##*:}"
    echo "── $DIR"

    xcrun simctl shutdown "$UDID" 2>/dev/null || true
    xcrun simctl erase "$UDID"
    xcrun simctl boot "$UDID"
    xcrun simctl bootstatus "$UDID" -b >/dev/null
    # iPad/iPhone status-bar date follows the SIMULATOR language, not the app's
    xcrun simctl spawn "$UDID" defaults write .GlobalPreferences AppleLanguages -array "$LANG_CODE"
    # kill the one-off keyboard tutorials before they land on a screenshot
    xcrun simctl spawn "$UDID" defaults write com.apple.keyboard.preferences \
        DidShowContinuousPathIntroduction -bool true 2>/dev/null || true
    xcrun simctl spawn "$UDID" defaults write com.apple.Preferences \
        DidShowContinuousPathIntroduction -bool true 2>/dev/null || true
    xcrun simctl spawn "$UDID" defaults write com.apple.keyboard.preferences \
        KeyboardDidShowProductivityTutorial -bool true 2>/dev/null || true

    xcrun simctl status_bar "$UDID" override \
        --time "09:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

    RESULT="build/xcresult/${DIR}.xcresult"
    rm -rf "$RESULT"; mkdir -p build/xcresult

    SCREENSHOT_LANG="$LANG_CODE" SCREENSHOT_LOCALE="$LOCALE" \
    xcodebuild test \
        -project Tack.xcodeproj -scheme Tack -configuration Debug \
        -destination "id=$UDID" \
        -only-testing:TackUITests/ScreenshotTests \
        -resultBundlePath "$RESULT" \
        SCREENSHOT_LANG="$LANG_CODE" SCREENSHOT_LOCALE="$LOCALE" \
        2>&1 | grep -E "Test Case|error:|TEST (SUCCEEDED|FAILED)" || true

    mkdir -p "$OUT/$DIR"
    python3 scripts/extract_shots.py "$RESULT" "$OUT/$DIR"
done

echo
echo "✅ screenshots:"
find "$OUT" -name "*.png" | sort
