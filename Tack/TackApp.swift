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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(integrations)
                .preferredColorScheme(nil)   // Honor system; user can override in Settings.
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
