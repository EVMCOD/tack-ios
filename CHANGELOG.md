# Tack changelog

All notable changes to **Tack**. Dates are Europe/Madrid (UTC+1/+2).

## v1.0.0 — 2026-09-08

Initial release. Targeting iPhone + iPad (iOS 17.0+). App Store submission package.

### Added
- Today, Inbox, Lists, Stats, Settings tabs with adaptive shell (tab on iPhone, NavigationSplitView on iPad)
- Quick Add sheet with **natural language parser** (`#tag`, `!priority`, `today|tomorrow|next weekday`, `in N days|hours|minutes`, `5pm|17:30`)
- Three Home Screen widgets (Today, Inbox, Stats) — small, medium and large
- Interactive widget tap-to-complete via `AppIntent`
- Stat dashboard with streak counter and 14-day Swift Charts visualization
- Global search across title, notes, list and tags
- Onboarding flow (3 slides; Obsidian-only sync step hooked)
- Siri + Shortcuts + Share Sheet integration via `AppIntents`
  - `AddTaskIntent` — parses natural language
  - `CompleteTaskIntent`
  - `QuickCaptureIntent`
- **Obsidian** integration: vault folder picker via security-scoped bookmark + YAML frontmatter serializer; bidirectional sync
- Widget bundle ID, App Group `group.app.tack.shared`
- Six locales: English, Spanish, French, German, Italian, Brazilian Portuguese
- `TK` design token system (palette, spacing, radius, typography, icon, spring, gradient)
- `PrivacyInfo.xcprivacy` with declared API reason codes (disk space, UserDefaults, file timestamp, system boot time)
- Fastlane skeleton (`fastlane/`) with archive, screenshots, upload, ship lanes
- App Store Connect metadata in `metadata/<locale>/` for all six locales
- Scripts: `archive.sh`, `submit.sh`, `screenshot.sh`, `lint.sh`, `render-icon-todo.swift`
- `SUBMIT.md` — submission playbook

### Status badge
- Build: `** BUILD SUCCEEDED **`, errors 0, warnings 0
- Universal architecture prepared for macOS target in v1.1 (all `#if os(macOS)` branches in place)
- iCloud sync toggle wired in Settings, awaiting CloudKit container setup in v1.1

### Known limitations
- macOS native target deferred to v1.1
- Native iCloud sync (CloudKit) deferred to v1.1 — currently iCloud backs up the App Group container
- In-app recurring tasks deferred to v1.1
- Live file-watching inside Obsidian vault supported only on macOS (granular FS events unavailable on iOS)
- Notion integration deferred to v1.1 (OAuth flow not wired in v1.0)
