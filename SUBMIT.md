# SUBMIT · Tack v1.0 → App Store

This is the one-page playbook for shipping **Tack**. Run through it once and you're done.

---

## ⏱ Time to ship

| Scenario | ETA |
|---|---|
| Compiled and shipped (skip optional steps) | ~30 min of your time + Apple review queue |
| Polished: TestFlight round + screenshots + ASO polish | ~3 hours |

---

## Pre-flight (you, ~15 minutes)

```bash
cd ~/tack-ios

# 1. Validation gate — ensures xcodegen + build + privacy manifest + metadata are green
./scripts/lint.sh

# 2. Notion (only if you want the integration live before launch)
#    - Create an integration at https://www.notion.so/profile/integrations
#    - Set its OAuth redirect URI to:   tack://oauth/notion
#    - Copy the client_id
#    - Replace REPLACE_WITH_YOUR_NOTION_CLIENT_ID in
#      Tack/Integrations/Notion/NotionAuthService.swift

# 3. Privacy manifest — already present
ls Tack/PrivacyInfo.xcprivacy
```

Checklist:

- [ ] `bundle ID app.tack.ios` registered in Apple Developer
- [ ] App Group `group.app.tack.shared` registered for both bundle + widget
- [ ] Distribution certificate in your Keychain
- [ ] Provisioning profile: *iOS App Store* for `app.tack.ios`
- [ ] (Optional) App-Specific password for Apple ID (`apple.com → Apple ID → Sign-In & Security`)
- [ ] (Optional) Notion integration ID pasted into the Swift file

---

## Day 1 · Build + screenshots + archive

### 1) Install tooling

```bash
brew install xcodegen fastlane
# xcpretty is optional but pretty:
sudo gem install xcpretty
```

### 2) Capture screenshots

```bash
./scripts/screenshot.sh
# → ./build/screenshots/<device>/<locale>/*.png
```

`snapshot` boots a simulator, runs the app, and drives it through the on-device
scenarios in `fastlane/SnapshotFile`. Produces three device lines (iPhone 17 Pro,
iPhone Air, and one more if you add it).

Re-run any time you change UI.

### 3) Validate everything is green

```bash
./scripts/lint.sh
# 🟢  All gate checks passed.
```

### 4) Archive for App Store

```bash
./scripts/archive.sh           # → ./build/Tack.ipa
```

The first run uses `--exportOptions.plist`. If you don't have one yet:

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
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=<from appleid.apple.com>
```

### 6) Upload (no submit-for-review yet)

```bash
./scripts/submit.sh ./build/Tack.ipa
# OR
fastlane ios upload
```

`fastlane ios upload` reads `metadata/<locale>/` for screenshots, name, subtitle,
keywords, description, release notes. It also uploads the .ipa. Does NOT click
Submit for Review — you do that from App Store Connect to inspect the diff.

### 7) Verify on App Store Connect

https://appstoreconnect.apple.com → **Tack** → TestFlight / App Store Versions → 1.0

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
| `git push` rejected (archivos huge) | .gitignore excludes build/. Ensure `xcodegen generate` and you don't commit `Tack.xcodeproj`. |
| `xcodebuild` says `code signing failed` | Re-attach provisioning profile in Xcode → Signing & Capabilities → click Profile. |
| `fastlane ios upload` says "You have no team" | `fastlane spaceauth` to re-auth, or set `FASTLANE_TEAM_ID` env. |
| App rejected on Guideline 5.1.1 (Privacy) | `PrivacyInfo.xcprivacy` already covers the APIs we touch. If they ask for a privacy FAQ URL during review, provide one (a public site). |
| App rejected on Guideline 2.1 (crash on launch) | Check Crash logs in App Store Connect. Likely a SwiftData migration issue — make sure you incremented the schema or wiped the store. |
| App Store Connect: "Missing Compliance" | Answer "No" for Uses Third-Party SDK / Tracking / Encryption. Hit Save. |

---

## After approval

Once Apple notifies you the app is `READY_FOR_SALE`:

1. Release the version (Manual or Auto)
2. Promote build from TestFlight to production
3. Tag `git tag v1.0.0-prod` on the commit that shipped
4. Update `~/Documents/Obsidian/OC/projects/tack.md` with `READY_FOR_SALE` + ASC submission ID

---

## Reference

- `~/tack-ios/scripts/archive.sh` — wrapper around xcodebuild archive + exportOptions
- `~/tack-ios/scripts/submit.sh` — wrapper around `fastlane ios upload`
- `~/tack-ios/scripts/screenshot.sh` — wrapper around `fastlane ios screenshots`
- `~/tack-ios/scripts/lint.sh` — gate check (build + privacy + metadata)
- `~/tack-ios/fastlane/Fastfile` — `ship` lane chains everything
- `~/tack-ios/metadata/<locale>/` — App Store Connect copy in 6 languages
- `~/tack-ios/Tack/PrivacyInfo.xcprivacy` — required as of Xcode 15
- `~/Documents/Obsidian/OC/projects/tack.md` — daily tracker
