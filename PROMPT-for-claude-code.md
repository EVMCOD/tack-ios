# Ship Tack iOS to App Store — autonomous run for Claude Code

## CONTEXT YOU NEED

**App:** Tack — native todo app for iPhone and iPad, SwiftUI + SwiftData + WidgetKit, iOS 17+, bundle `app.tack.ios` (widget: `app.tack.ios.widget`), Team ID `KADHS6P8PY`, Apple ID `valerosenrique@gmail.com`.

**State of the repo** at HEAD = `d360de3` (already on `main`):
- ✅ Code is ship-ready: 41 Swift files, 0 errors, 0 warnings.
- ✅ Lint gate green (`scripts/lint.sh`).
- ✅ `Tack/PrivacyInfo.xcprivacy` present.
- ✅ App Store Connect metadata in 6 locales pre-written at `metadata/<locale>/`.
- ✅ Fastlane skeleton in `fastlane/Fastfile` with `register / test / archive / screenshots / upload / ship` lanes.
- ✅ Submission scripts: `scripts/lint.sh`, `scripts/archive.sh`, `scripts/screenshot.sh`, `scripts/submit.sh`.
- ✅ Repository pushed to `github.com/EVMCOD/tack-ios`.
- ❌ **Bundle ID `app.tack.ios` is NOT registered in Apple Developer yet** — this is the only blocker. No provisioning profile exists on this Mac for it.

**User context:**
- macOS 26.6, Xcode 26, iPhone 17 Pro simulator booted but irrelevant to the shipping flow.
- The user is at the keyboard and will type Apple ID + 2FA codes when prompted.
- The user has 5 minutes of patience and wants to ship tonight.
- If you need an Apple ID, ask. Don't assume.

## YOUR JOB

Walk through steps 1–6 below, in order, each time reporting success or failure with the exact command that failed and a one-line remediation. Do not skip steps. Do not modify source code unless a build fails. If a step fails twice, stop and ask the user — don't loop.

```
WORKDIR = /Users/enriquevaleros/tack-ios
BUNDLE  = app.tack.ios
WIDGET  = app.tack.ios.widget
TEAM    = KADHS6P8PY
APPLEID = valerosenrique@gmail.com
TARGET_BRANCH = main
```

## STEP 1 — Verify state

```bash
cd "$WORKDIR" && ./scripts/lint.sh
```

Must show `🟢  All gate checks passed.` If not, debug and re-run. Do not proceed past this step if build is broken.

## STEP 2 — Register bundle ID + sign the build

Two options. **Try Option B first** (fastlane register handles both bundle ID + profile + signing in one shot). Fall back to Option A if interactive prompts don't work.

### Option B (preferred): fastlane register

```bash
cd "$WORKDIR"
fastlane spaceauth
# → Follow the Apple ID + 2FA prompts that appear
fastlane ios register
# → Confirms bundle IDs and team
```

If `fastlane ios register` complains that it already exists, that's fine — move on.

### Option A (fallback): Xcode UI

```bash
open "$WORKDIR/Tack.xcodeproj"
# Then ask the user to perform these steps in Xcode:
#   1. Click target 'Tack' in sidebar.
#   2. Open "Signing & Capabilities" tab.
#   3. Tick "Automatically manage signing".
#   4. Team dropdown: ENRIQUE VALEROS MURIANA (KADHS6P8PY).
#   5. Confirm "Register bundle — Enable" popup.
#   6. Repeat for 'TackWidget' target.
#   7. Wait until both targets show a non-empty provisioning profile.
#   8. Close Xcode.
```

After either option, verify the profile exists locally:

```bash
ls -lh ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision
# Should show ≥1 recent file
find ~/Library/MobileDevice/Provisioning\ Profiles -mtime -1h
```

## STEP 3 — Archive the build

```bash
cd "$WORKDIR"
./scripts/archive.sh
```

Expected: ends with `✅ Archive + IPA ready at: …/Tack.xcarchive …/Tack.ipa`. Files: `./build/Tack.ipa` and `./build/Tack.xcarchive`.

If signing fails with "no profile found":
- Verify bundle ID is registered (Step 2).
- For a quick retry: `cd "$WORKDIR" && xcodebuild -project Tack.xcodeproj -scheme Tack -configuration Release -destination "generic/platform=iOS" -archivePath build/Tack.xcarchive archive -allowProvisioningUpdates`
- Verify TEAM id: `xcodebuild -project "$WORKDIR/Tack.xcodeproj" -showBuildSettings | grep DEVELOPMENT_TEAM` should print `KADHS6P8PY`.

## STEP 4 — Capture App Store screenshots

```bash
cd "$WORKDIR"
./scripts/screenshot.sh
```

Output: `./build/screenshots/<device>/<locale>/*.png`. If snapshot UI tests aren't set up yet, snapshot will fall back to manual captures — accept whatever ships. The user can re-run later.

## STEP 5 — Upload to App Store Connect

```bash
cd "$WORKDIR"
./scripts/submit.sh ./build/Tack.ipa
```

Equivalent to `fastlane ios upload --ipa ./build/Tack.ipa --skip_binary_upload false --skip_screenshots false --skip_metadata false --submit_for_review false`. Walks through Apple ID + 2FA. Does NOT click Submit for Review — that's the user's call after they verify in App Store Connect.

If `submit.sh` errors with "No code signing identity found", the bundle is not yet registered. Re-run Step 2.

If you see Transporter-style errors about schema migrations, fall back to:

```bash
xcrun altool --upload-app -f ./build/Tack.ipa -t ios -u "$APPLEID"
```

## STEP 6 — Verify + Submit

Ask the user to open `https://appstoreconnect.apple.com` → **Tack → 1.0 (Pending)**.

Walk through with them (don't auto-navigate — they own the session):

- [ ] App icon preview chip renders.
- [ ] Description renders cleanly (no broken markdown / emoji).
- [ ] Age rating questionnaire: select **4+**, "No Objectionable Content".
- [ ] Pricing: Free (or whatever they want).
- [ ] Availability: All territories or user-selected.
- [ ] Encryption: **"Uses Non-Exempt Encryption: NO"** — already declared in Info.plist.
- [ ] Privacy questions: walked through, no required-data collection.

User clicks **"Submit for Review"**. After Apple's app review window (24–48 hours), Tack goes `READY_FOR_SALE`.

## GUARDRAILS

- **Never** submit for review on the user's behalf. Step 6 is their call.
- **Never** modify `project.yml`, source Swift files, or `metadata/<locale>/` unless a build step explicitly requires it.
- **Always** surface the full error message if any step fails, plus the next command the user should try.
- **Always** ask before doing any web fetch, repo push, or destructive shell action.
- After Step 5 succeeds, do not modify code — proceed straight to verification.

## REPORT BACK

When done, print a single block like:

```
✅ Step 1  lint gate
✅ Step 2  bundle app.tack.ios registered (or: provisioning profile present, <profile name>)
✅ Step 3  archived → ./build/Tack.ipa (size MB)
✅ Step 4  screenshots saved → ./build/screenshots/<device>/<locale>/*.png (count files)
✅ Step 5  uploaded to App Store Connect — version 1.0 build 1 status: <Received / Invalid / etc>
⏸  Step 6  paused for user verification in App Store Connect

If anything failed, list the failing command + the most likely fix.
```

## START

Begin with Step 1. Report the lint gate status before going on.
