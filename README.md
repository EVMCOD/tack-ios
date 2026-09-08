# Tack

> A focused, adaptive task app for iPhone, iPad, and macOS. Notion & Obsidian native. Widgets that pull their weight.

## What is it?

A native todo app built around three ideas:

1. **Capture in one tap** — the floating `+` button on iPhone, the prominent sidebar CTA on macOS. Natural language parsing turns "Buy milk tomorrow 5pm #groceries" into a structured task.
2. **Today / Inbox / Lists / Stats / Settings** — five views, no friction. Tasks naturally find their home; `Stats` gamifies with a streak counter and last 14-day chart.
3. **Sync where you think** — Notion for team databases, Obsidian for personal vaults. Bidirectional. YAML frontmatter on every markdown file so other tools (Dataview, Templater) can read them.

## Stack

- **SwiftUI** (iOS 17.0 / macOS 14.0)
- **SwiftData** for persistence (App Group → shared with widget)
- **WidgetKit** + interactive `AppIntent` widgets
- **AppIntents** framework for Siri, Shortcuts, Spotlight
- **xcodegen** for project generation
- 6 locales: en, es, fr, de, it, pt-BR

## Features

### Core
- ✅ Today (smart default), Inbox (raw captures), Lists (your own grouping), Stats, Settings
- ✅ Quick Add sheet with live natural language parsing
  - `#tag` → tags
  - `today`, `tomorrow`, `next monday|...` → date
  - `in 3 days`, `in 2h`, `in 30m` → relative
  - `5pm`, `17:30` → time (today or tomorrow if past)
  - `!high`, `!med`, `!low`, `!urgent` → priority
- ✅ Search across title, notes, list, tags
- ✅ Onboarding flow (3 slides)
- ✅ Light / Dark / system theme picker
- ✅ iCloud sync toggle (CloudKit — v1.1 wired)

### Widgets
- ✅ TodayWidget (small/medium/large)
- ✅ InboxWidget (small/medium)
- ✅ StatsWidget (small/medium) — streak + last 7 days chart

### Integrations
- ✅ **Notion** — OAuth PKCE flow, REST client, bidirectional sync with status + due date
- ✅ **Obsidian** — Vault folder picker via security-scoped bookmark, YAML frontmatter markdown serializer, two-way sync

### AppIntents
- ✅ `AddTaskIntent` — Siri / Shortcut / share extension. Parses natural language.
- ✅ `CompleteTaskIntent` — Mark task done by title query.
- ✅ `QuickCaptureIntent` — Open app, prefill Quick Add from elsewhere.

## Architecture

```
tack-ios/
├── project.yml                     # xcodegen (universal config; iOS target v1.0, macOS v1.1)
├── README.md
├── ICON.md                         # App icon design spec
├── Tack/
│   ├── TackApp.swift               # @main entry, scenePhase observers
│   ├── Theme/Theme.swift           # TK tokens (palette, radius, spacing, typography, icon, spring, gradient)
│   ├── Models/                     # SwiftData @Model classes
│   │   ├── TaskItem.swift
│   │   ├── TaskList.swift
│   │   └── Tag.swift
│   ├── Stores/
│   │   ├── TaskStore.swift         # @MainActor, App Group container
│   │   └── AppSettings.swift       # @AppStorage prefs
│   ├── Views/
│   │   ├── RootView.swift          # iOS TabView / macOS NavigationSplitView + onboarding gate
│   │   ├── OnboardingView.swift    # 3-slide first launch
│   │   ├── TodayView.swift
│   │   ├── InboxView.swift
│   │   ├── ListsView.swift
│   │   ├── StatsView.swift         # Swift Charts: streak, 14-day, by-list
│   │   ├── SearchView.swift
│   │   ├── TaskDetailView.swift
│   │   ├── TaskRowView.swift
│   │   ├── QuickAddSheet.swift     # NL parsing preview
│   │   ├── EmptyStateView.swift
│   │   ├── SettingsView.swift
│   │   └── Integrations/
│   │       ├── NotionSettingsView.swift
│   │       └── ObsidianSettingsView.swift
│   ├── Integrations/
│   │   ├── IntegrationHub.swift    # facade orchestrator
│   │   ├── Notion/
│   │   │   ├── NotionClient.swift
│   │   │   ├── NotionAuthService.swift
│   │   │   └── NotionSyncService.swift
│   │   └── Obsidian/
│   │       ├── ObsidianVault.swift
│   │       └── ObsidianSyncService.swift
│   ├── Intents/                    # AppIntents + AppShortcuts
│   ├── Services/
│   │   ├── KeychainStore.swift
│   │   ├── MarkdownSerializer.swift
│   │   ├── NaturalLanguageParser.swift
│   │   └── Logger.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Localizable.xcstrings   # 6 locales, 16 strings
│   ├── Info.plist
│   └── Tack.entitlements
├── TackWidget/                     # Widget extension target
│   ├── TackWidgetBundle.swift
│   ├── TodayWidget.swift
│   ├── InboxWidget.swift
│   ├── StatsWidget.swift
│   ├── TimelineProvider.swift
│   ├── TaskEntry.swift
│   ├── WidgetTaskLoader.swift
│   ├── Info.plist
│   └── TackWidget.entitlements
├── TackUITests/
│   └── TackUITests.swift
└── scripts/
    ├── bootstrap.sh                # xcodegen + xcodebuild sanity
    ├── generate.sh                 # xcodegen only
    ├── build.sh                    # build for iPhone simulator
    └── test.sh                     # run UI tests
```

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

## Roadmap

- [x] v1.0 — Core + Stats + Search + NL Parser + 6 locales
- [x] v1.0 — Integrations: Notion (OAuth + bidirectional), Obsidian (folder + bidirectional)
- [ ] v1.1 — macOS native target, CloudKit sync, recurrence engine, Apple Reminders import
- [ ] v1.2 — Watch app, Calendar export (.ics), Notification Center widget
- [ ] v2.0 — Shared lists (collaboration)

## Build status

```
$ ./scripts/build.sh
** BUILD SUCCEEDED **

Errors:   0
Warnings: 8 (4 Swift 6 TimelineProvider readiness, 4 AppIcon.png expected missing)
Files:    43 Swift + project.yml + xcstrings + plists + entitlements + assets + 4 scripts
LOC:      3932 Swift
```

## License

Private. © 2026.
