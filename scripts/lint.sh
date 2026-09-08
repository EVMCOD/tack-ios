#!/usr/bin/env bash
#
# lint.sh — Gate check before merging anything to main. Verifies:
#   1. xcodegen produces a valid .xcodeproj from project.yml
#   2. xcodebuild Debug succeeds clean (0 errors, ≥ known Swift-6 warnings)
#   3. PrivacyInfo.xcprivacy exists + is valid XML
#   4. All metadata/<locale>/name.txt files present + non-empty
#
set -euo pipefail

cd "$(dirname "$0")/.."

ERRORS=0

step() {
    echo ""
    echo "── $1"
}

fail() {
    echo "❌  $1"
    ERRORS=$((ERRORS + 1))
}

# 1. project.yml → .xcodeproj
step "1/4  xcodegen generate"
if xcodegen generate --quiet; then
    echo "✅  .xcodeproj regenerated"
else
    fail "xcodegen failed"
fi

# 2. Build clean
step "2/4  xcodebuild Debug (iOS Simulator)"
LOG=/tmp/tack-lint-build.log
if xcodebuild \
        -project Tack.xcodeproj \
        -scheme Tack \
        -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
        -configuration Debug \
        build > "$LOG" 2>&1; then
    ECOUNT=$(grep -c "error:" "$LOG" 2>/dev/null || echo 0)
    WCOUNT=$(grep -c "warning:" "$LOG" 2>/dev/null || echo 0)
    echo "✅  Build SUCCEEDED · errors=$ECOUNT, warnings=$WCOUNT"
else
    ERR_COUNT=$(grep -c "error:" "$LOG" 2>/dev/null || echo 0)
    fail "Build failed with $ERR_COUNT errors — see $LOG"
fi

# 3. PrivacyInfo.xcprivacy
step "3/4  PrivacyInfo.xcprivacy"
PI="Tack/PrivacyInfo.xcprivacy"
if [[ -f "$PI" ]]; then
    if python3 -c "import plistlib; plistlib.load(open('$PI','rb')); print('valid')" 2>/dev/null | grep -q valid; then
        echo "✅  $PI is valid XML plist"
    else
        fail "$PI does not parse as XML plist"
    fi
else
    fail "$PI missing"
fi

# 4. Metadata files
step "4/4  App Store metadata"
LOCALES=(en-US es-ES fr-FR de-DE it-IT pt-BR)
FILES=(name subtitle keywords description release_notes)
MISSING=0
for locale in "${LOCALES[@]}"; do
    for f in "${FILES[@]}"; do
        path="metadata/$locale/$f.txt"
        if [[ ! -s "$path" ]]; then
            echo "   ⚠️  Missing or empty: $path"
            MISSING=$((MISSING + 1))
        fi
    done
done
if [[ $MISSING -eq 0 ]]; then
    echo "✅  All 6 locales × 5 files present"
else
    fail "$MISSING metadata file(s) missing"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🟢  All gate checks passed."
    exit 0
else
    echo "🔴  $ERRORS gate check(s) failed."
    exit 1
fi
