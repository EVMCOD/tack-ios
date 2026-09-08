# SUBMIT · Tack v1.0 → App Store

This is the one-page playbook for shipping **Tack**. Run through it once and you're done.

---

## ⏱ Time to ship

| Scenario | ETA |
|---|---|
| Compiled and shipped | ~15 min of your time + Apple review queue |
| Polished: TestFlight round + screenshots + ASO polish | ~3 hours |

---

## Pre-flight (you, ~10 minutes)

```bash
cd ~/tack-ios

./scripts/lint.sh    # build + privacy plist + metadata all green
```

Checklist:

- [ ] `bundle ID app.tack.ios` registered in Apple Developer
- [ ] App Group `group.app.tack.shared` registered for both bundle + widget
- [ ] Distribution certificate in your Keychain
- [ ] Provisioning profile: *iOS App Store* for `app.tack.ios`
- [ ] (Optional) App-Specific password for Apple ID (`appleid.apple.com → Sign-In & Security`)

Tack v1.0 ships with **one integration** (Obsidian). No third-party OAuth setup is
required to ship — the Obsidian integration is opt-in via a folder picker inside the
app. The Notion OAuth client_id placeholder was removed for v1.0.

---

## Day 1 · Build + screenshots + archive

### 1) Install tooling

```bash
brew install xcodegen fastlane
```

### 2) Capture screenshots

```bash
./scripts/screenshot.sh
# → ./build/screenshots/<device>/<locale>/*.png
```

`snapshot` boots a simulator, runs the app, and drives it through the on-device
scenarios in `fastlane/SnapshotFile`.

### 3) Validate everything is green

```bash
./scripts/lint.sh
# 🟢  All gate checks passed.
```

### 4) Archive for App Store

```bash
./scripts/archive.sh           # → ./build/Tack.xcarchive + Tack.ipa
```

First run uses `--exportOptions.plist`. If you don't have one yet:

```bash
cat > build/exportOptions.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store</string>
    <key>teamID</key><string>KADHS6P8PY</string>
    <key>uploadSymbols</key><false/>
</dict>
</plist>
EOF
```

---

## Day 1/2 · Upload metadata + binary

### 5) Sign in to Fastlane Spaceship (one-time)

```bash
fastlane spaceauth
# OR via env
export APPLE_ID_FOR_TACK=valerosenrique@gmail.com
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=***  # appleid.apple.com>
```

### 6) Upload (no submit-for-review yet)

```bash
./scripts/submit.sh ./build/Tack.ipa
# OR
fastlane ios upload
```

`fastlane ios upload` reads `metadata/<locale>/` for screenshots, name, subtitle,
keywords, description, release notes. It also uploads the `.ipa`. Does NOT click
Submit for Review — you do that from App Store Connect to inspect the diff.

### 7) Verify on App Store Connect

[App Store Connect → Tack](https://appstoreconnect.apple.com)

Walk through every tab (Versions, App Store, Pricing). Confirm:
- App icon preview looks right (the small chip in the upper left)
- Screenshots per device + locale appear in the carousel
- Description renders cleanly (paragraphs, emoji, line breaks)
- Age rating questionnaire completed (4+, no objectionable content)
- Encryption: "Uses Non-Exempt Encryption: No" (already in Info.plist)
- Pricing set; Availability set; App Privacy answers set

### 8) Ship it

Once the diff is reviewed:

```bash
fastlane ios upload --submit_for_review true
# OR click Submit for Review in App Store Connect.
```

Then wait. Apple's first review for new apps typically lands in 24–48 hours. Older
updates clear in under 24h. TestFlight still works during the wait — post a build to
internal testers if you want to validate first.

---

## One-time per Apple Developer account

If `app.tack.ios` doesn't yet exist in your dev account:

```bash
fastlane ios register
```

This creates the App ID, enables the App Group capability, and registers the
bundle. Run once, then come back to the pre-flight checklist.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `git push` rejected | .gitignore excludes build/. Ensure `xcodegen generate` and that you don't commit `Tack.xcodeproj`. |
| `xcodebuild` says `code signing failed` | Re-attach provisioning profile in Xcode → Signing & Capabilities → click Profile. |
| `fastlane ios upload` says "You have no team" | `fastlane spaceauth` to re-auth, or set `FASTLANE_TEAM_ID`. |
| App rejected on Guideline 5.1.1 (Privacy) | `PrivacyInfo.xcprivacy` covers all declared reason APIs. If they ask for a privacy FAQ URL, point to a public site. |
| App rejected on Guideline 2.1 (crash on launch) | Check Crash logs in App Store Connect. Likely a SwiftData migration issue — increment schema or wipe store. |
| App Store Connect: "Missing Compliance" | Answer "No" for Tracking / Encryption. Save. |

---

## After approval

Once Apple notifies you the app is `READY_FOR_SALE`:

1. Release the version (Manual or Auto)
2. Promote build from TestFlight to production
3. Tag `git tag v1.0.0-prod` on the commit that shipped
4. Update `~/Documents/Obsidian/OC/projects/tack.md` with `READY_FOR_SALE` + ASC submission ID

---

## Reference

- `scripts/archive.sh` — wrapper around xcodebuild archive + exportOptions
- `scripts/submit.sh` — wrapper around `fastlane ios upload`
- `scripts/screenshot.sh` — wrapper around `fastlane ios screenshots`
- `scripts/lint.sh` — gate check (build + privacy + metadata)
- `fastlane/Fastfile` — `ship` lane chains everything
- `metadata/<locale>/` — App Store Connect copy in 6 languages
- `Tack/PrivacyInfo.xcprivacy` — required as of Xcode 15
- `~/Documents/Obsidian/OC/projects/tack.md` — daily tracker
