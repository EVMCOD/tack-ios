import SwiftUI
import SwiftData
import AppIntents

@main
struct TackApp: App {
    @StateObject private var store = TaskStore.shared
    @StateObject private var integrations = IntegrationHub.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register AppIntents shortcut phrases as soon as possible.
        TackAppShortcuts.updateAppShortcutParameters()
        // Seed demo data on first launch so the UI looks inhabited, not empty.
        TaskStore.shared.seedDemoDataOnFirstLaunch()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(integrations)
                // v1.0 is dark-only: every surface uses the fixed dark palette
                // (TK.Palette.bgDeep et al) while text is adaptive, so a light
                // scheme renders black-on-black. Light theme lands in v1.1.
                // NOTE: this outer modifier overrides anything RootView sets.
                .preferredColorScheme(.dark)
        }
        .modelContainer(store.container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                integrations.scheduleBackgroundRefresh()
            case .active:
                integrations.refreshOnLaunch()
            default:
                break
            }
        }
    }
}
