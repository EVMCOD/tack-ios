# Tack

> A focused, adaptive task app for iOS and macOS. Notion & Obsidian native. Widgets that pull their weight.

## What is it?

Tack is a native todo app built for one thing: **capture, organize, and complete tasks across every Apple device you own**. Today view. Inbox. Lists. Tags. Due dates. Recurrence. And — the part that matters to power users — bidirectional sync with **Notion** databases and **Obsidian** vaults.

It is **not** a clone of Reminders. It does not try to be Things. It is a small, sharp tool that respects your second-brain setup.

## Stack

- **SwiftUI** (iOS 17.0 / macOS 14.0)
- **SwiftData** for persistence (App Group → shared with widget)
- **WidgetKit** + interactive `AppIntent` widgets
- **AppIntents** framework for Siri, Shortcuts, Spotlight
- **xcodegen** for project generation
- 6 locales (en, es, fr, de, it, pt-BR)

## Architecture

```
tack-ios/
├── Tack/                # Main app (iOS + macOS universal)
│   ├── Theme/          # Design tokens
│   ├── Models/         # SwiftData @Model classes
│   ├── Stores/         # @Observable stores + ModelContainer setup
│   ├── Views/          # SwiftUI screen tree
│   ├── Integrations/   # Notion + Obsidian adapters
│   ├── Intents/        # AppIntents for Shortcuts/Siri
│   ├── Services/       # Keychain, Markdown, Logger
│   ├── Resources/      # Assets + Localizable
│   ├── Info.plist
│   └── Tack.entitlements
│
├── TackWidget/         # Widget extension (WidgetKit)
│   ├── TodayWidget.swift
│   ├── InboxWidget.swift
│   ├── TimelineProvider.swift
│   └── Info.plist
│
├── TackUITests/        # XCUITests
├── scripts/            # bootstrap, generate, build, submit
└── project.yml         # xcodegen config
```

## Quick start

```bash
./scripts/bootstrap.sh     # xcodegen + xcodegen lint sanity
open Tack.xcodeproj        # Open in Xcode
```

Or all from CLI:

```bash
./scripts/generate.sh
xcodebuild -project Tack.xcodeproj \
  -scheme Tack \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -configuration Debug \
  build
```

## Integrations

### Notion

OAuth 2.0 flow. Token stored in Keychain. Background sync via `BGTaskScheduler`. Maps a configured Notion database to a Tack list.

**Setup:** Settings → Integrations → Notion → Sign in → pick database.

### Obsidian

Picks a folder (your vault root). Each task is a markdown file with YAML frontmatter. Two-way sync runs on app launch and on background refresh.

**Setup:** Settings → Integrations → Obsidian → Pick vault folder.

## Roadmap

- [x] v1.0 — Core: Inbox, Today, Lists, Tags, Widgets (small/medium/large interactive), AppIntents
- [x] v1.0 — Integrations: Notion (OAuth + bidirectional), Obsidian (folder + bidirectional)
- [ ] v1.1 — Recurrence engine, Apple Reminders import, Calendar export, iCloud sync
- [ ] v1.2 — Watch app, complication
- [ ] v2.0 — Collaboration (shared lists)

## License

Private. © 2026.
