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
    # Parsing as XML is not enough: build 3 was rejected with ITMS-91056 for a
    # manifest that parsed fine but used NSPrivacyAccessedAPIReasons instead of
    # NSPrivacyAccessedAPITypeReasons, dropped the "Category" infix from every
    # API type, and cited CA1007, which is not a valid reason code. Apple names
    # none of that in the rejection, so check the spellings here.
    if PI="$PI" python3 - <<'PYCHECK'
import os, plistlib, sys

VALID = {
    "NSPrivacyAccessedAPICategoryFileTimestamp":  {"DDA9.1","C617.1","3B52.1","0A2A.1"},
    "NSPrivacyAccessedAPICategorySystemBootTime": {"35F9.1","8FFB.1","3D61.1"},
    "NSPrivacyAccessedAPICategoryDiskSpace":      {"E174.1","85F4.1","7D9E.1","B728.1"},
    "NSPrivacyAccessedAPICategoryActiveKeyboards":{"3EC4.1","54BD.1"},
    "NSPrivacyAccessedAPICategoryUserDefaults":   {"CA92.1","1C8F.1","C56D.1","AC6B.1"},
}
path = os.environ["PI"]
try:
    d = plistlib.load(open(path, "rb"))
except Exception as e:
    print(f"does not parse: {e}"); sys.exit(1)

bad = []
for key in ("NSPrivacyTracking", "NSPrivacyCollectedDataTypes", "NSPrivacyAccessedAPITypes"):
    if key not in d:
        bad.append(f"missing top-level {key}")
for i, e in enumerate(d.get("NSPrivacyAccessedAPITypes", [])):
    t = e.get("NSPrivacyAccessedAPIType")
    if t not in VALID:
        bad.append(f"entry {i}: unknown API type {t!r}"); continue
    if "NSPrivacyAccessedAPIReasons" in e:
        bad.append(f"entry {i}: key must be NSPrivacyAccessedAPITypeReasons")
    for r in e.get("NSPrivacyAccessedAPITypeReasons", []) or []:
        if r not in VALID[t]:
            bad.append(f"entry {i}: {r!r} is not a valid reason for {t}")
    if not e.get("NSPrivacyAccessedAPITypeReasons"):
        bad.append(f"entry {i}: no reasons given for {t}")
if bad:
    for b in bad: print(b)
    sys.exit(1)
print("valid")
PYCHECK
    then
        echo "✅  $PI keys and reason codes are valid"
    else
        fail "$PI is not a valid privacy manifest (see above)"
    fi
else
    fail "$PI missing"
fi

# 4. Metadata files
step "4/4  App Store metadata"
LOCALES=(en-US es-ES fr-FR de-DE it pt-BR)
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
