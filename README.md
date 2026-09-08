# Tack

> A focused, adaptive task app for iPhone and iPad. Notion & Obsidian native. Widgets that pull their weight.

## What is it?

A native todo app that pairs a sharp everyday workflow with bidirectional **Notion** and **Obsidian** sync — so your tasks live where you actually think.

- Capture in one tap with **natural language** parsing: "Buy milk tomorrow 5pm #groceries"
- Five tabs: Today, Inbox, Lists, Stats, Settings
- Three interactive Home Screen **widgets**
- **AppIntents** for Siri, Shortcuts, and the Share Sheet
- Six built-in **locales**
- 100% **offline**, no tracking, no ads, no server

## Stack

- SwiftUI (iOS 17.0+, iPadOS 17.0+, macOS in v1.1)
- SwiftData with App Group storage
- WidgetKit + interactive `AppIntent`
- AppIntents framework
- xcodegen, Fastlane
- 6 locales: en, es, fr, de, it, pt-BR

## Features

### Core

- ✅ Today (smart default), Inbox (raw captures), Lists (your own grouping), **Stats** (Swift Charts), Settings
- ✅ Quick Add with natural language parser
  - `#tag` → tags
  - `today`, `tomorrow`, `next monday|...` → date
  - `in 3 days`, `in 2h`, `in 30m` → relative
  - `5pm`, `17:30` → time
  - `!high`, `!med`, `!low`, `!urgent` → priority
- ✅ Search across title, notes, list, tags
- ✅ Onboarding flow (3 slides; integrations step included)
- ✅ Light / Dark / system theme picker
- ✅ iCloud sync toggle (CloudKit — v1.1 wired)

### Widgets

- ✅ TodayWidget (small/medium/large)
- ✅ InboxWidget (small/medium)
- ✅ StatsWidget (small/medium) — streak + last 7 days chart

### Integrations

- ✅ **Notion** — OAuth PKCE + bidirectional sync with status + due date
- ✅ **Obsidian** — Vault folder picker via security-scoped bookmark + YAML-frontmatter markdown

### AppIntents

- ✅ `AddTaskIntent` — Siri / Shortcut / share extension. Parses natural language.
- ✅ `CompleteTaskIntent` — Mark task done by title query.
- ✅ `QuickCaptureIntent` — Open app, prefill Quick Add from elsewhere.

## Quick start

```bash
cd ~/tack-ios
./scripts/bootstrap.sh     # xcodegen + xcodebuild sanity
open Tack.xcodeproj
```

Or pure CLI:
```bash
./scripts/build.sh
```

## Shipping

For the full App Store submission playbook, see **[SUBMIT.md](./SUBMIT.md)**.

In short:

```bash
./scripts/lint.sh           # gate check (build + privacy + metadata)
./scripts/screenshot.sh     # capture App Store screenshots
./scripts/archive.sh        # build signed .ipa
./scripts/submit.sh         # upload to App Store Connect
```

Or chained:

```bash
fastlane ios ship
```

## Roadmap

- [x] v1.0 — Core + Stats + Search + NL Parser + 6 locales + ASO copy in 6 languages
- [x] v1.0 — Integrations: Notion + Obsidian, two-way
- [ ] v1.1 — macOS native target, CloudKit sync, recurrence engine, Apple Reminders import
- [ ] v1.2 — Watch app, Calendar export (.ics)
- [ ] v2.0 — Shared lists (collaboration)

## Build status

```
$ ./scripts/lint.sh
🟢  All gate checks passed.

Errors:   0
Warnings: 4 (Swift 6 TimelineProvider readiness, inertes)
Files:    45 Swift + project.yml + xcprivacy + xcstrings + plists + entitlements + assets + 4 scripts
LOC:      ~4000 Swift
```

## License

Private. © 2026.
