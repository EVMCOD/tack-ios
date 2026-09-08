# Tack · Fastlane

Automation for building, screenshotting, and uploading **Tack** to App Store Connect.

## Setup (one-time)

```bash
brew install fastlane
cd ~/tack-ios
bundle install         # optional, if using Gemfile
```

Sign in once to each Apple service (one of):

```bash
# Fastlane Spaceship (recommended — drives everything from CLI)
fastlane spaceauth

# OR set env vars (good for CI)
export APPLE_ID_FOR_TACK=valerosenrique@gmail.com   # or App-Specific password below
export TACK_ITC_TEAM_ID=<your App Store Connect Team ID>
```

If you're using 2FA on the Apple Developer account, generate an App-Specific password
and use it via `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`.

## Lanes

| Lane | What it does | When to run |
|---|---|---|
| `fastlane ios test` | Runs the UI test suite via `scan` | Local check after schema changes |
| `fastlane ios archive` | Compiles a signed `Tack.ipa` ready for App Store | Before upload |
| `fastlane ios screenshots` | Drives the simulator and captures screenshots per device + locale | Before every release |
| `fastlane ios upload` | Uploads `Tack.ipa` + metadata + screenshots to App Store Connect (no submit) | Before submitting for review |
| `fastlane ios ship` | Chained: test → archive → screenshots → upload | When you want everything |
| `fastlane ios register` | Creates the bundle ID + App Group + capabilities in your dev account | First time only |

## Metadata

App Store Connect content lives in `../metadata/<locale>/`:
- `name.txt`         — app name (max 50 chars)
- `subtitle.txt`     — short tagline (max 30 chars)
- `keywords.txt`     — comma-separated keywords (max 100 chars)
- `description.txt`  — full long description (max 4000 chars)
- `release_notes.txt`— What's New for the current version (max 4000 chars)

Supported locales mirror the in-app xcstrings: en-US, es-ES, fr-FR, de-DE, it-IT, pt-BR.

After you tweak any of these, run `fastlane ios upload` to push.

## Screenshots

`snapshot` runs the app on real simulators, drives it via accessibility identifiers,
and saves PNGs at `build/screenshots/<device>/<locale>/`.

For Tack we ship three device lines:
- **iPhone 17 Pro** (6.3") — primary
- **iPhone Air** (6.6") — secondary
- (Add iPad if/when you flip on iPad support)

The simulator boots, the app launches, `snapshot` hits each scenario in `SnapshotTests/`,
and writes hero images. Then `fastlane ios upload` packs them into the App Store Connect
screenshot upload payload.

## Reference

- Fastlane docs: https://docs.fastlane.tools
- Privacy manifest: `../Tack/PrivacyInfo.xcprivacy`
- Submit playbook: `../SUBMIT.md`
