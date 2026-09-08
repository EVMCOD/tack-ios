import Foundation
import SwiftData
import SwiftUI

/// Single coordinator wiring every integration together. App-level facade so views
/// never import the integration modules directly.
@MainActor
public final class IntegrationHub: ObservableObject {
    public static let shared = IntegrationHub()

    @Published public private(set) var notion: IntegrationState = .notConfigured
    @Published public private(set) var obsidian: IntegrationState = .notConfigured
    @Published public private(set) var lastSync: Date?

    public enum IntegrationState: Equatable {
        case notConfigured, disconnected, syncing, error(String), ok

        public var label: String {
            switch self {
            case .notConfigured: return "Not configured"
            case .disconnected:  return "Disconnected"
            case .syncing:       return "Syncing…"
            case .error(let m):  return "Error: \(m)"
            case .ok:            return "Synced"
            }
        }
    }

    private let notionSync = NotionSyncService.shared
    private let obsidianSync = ObsidianSyncService.shared

    private init() {
        refreshState()
    }

    public func refreshState() {
        notion    = notionSync.isAuthorized && notionSync.isConfigured ? .ok : (notionSync.isConfigured ? .disconnected : .notConfigured)
        obsidian  = obsidianSync.isConfigured ? .ok : .notConfigured
    }

    /// Called when the app becomes active.
    public func refreshOnLaunch() {
        Task { await syncAll() }
    }

    /// Called when app enters background.
    public func scheduleBackgroundRefresh() {
        // BGTaskScheduler hookup goes here. Stubbed for v1.
    }

    /// Fan-out sync for both integrations. Pull/push in parallel.
    public func syncAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                self.notion = .syncing
                await NotionSyncService.shared.sync(container: TaskStore.shared.container)
                self.notion = self.notionSync.isAuthorized ? .ok : .disconnected
            }
            group.addTask { @MainActor in
                self.obsidian = .syncing
                ObsidianSyncService.shared.sync(container: TaskStore.shared.container)
                self.obsidian = self.obsidianSync.isConfigured ? .ok : .notConfigured
            }
        }
        lastSync = .now
    }

    /// Called from QuickAdd when a new task is created locally — push only.
    public func propagateToIntegrations(_ task: TaskItem) async {
        // Notion: only if configured; Obsidian: write file always if vault is set.
        if notionSync.isConfigured {
            await NotionSyncService.shared.sync(container: TaskStore.shared.container)
        }
        if obsidianSync.isConfigured {
            ObsidianSyncService.shared.sync(container: TaskStore.shared.container)
        }
    }

    // Notion helpers (forwarded for the Settings UI)
    public func notionAuthURL() async -> URL? {
        await notionSync.buildAuthURL()
    }

    public func notionAuthorize(_ url: URL) async {
        _ = await notionSync.authorize(url)
        refreshState()
    }

    public func notionPickDatabase(_ id: String) {
        notionSync.pickDatabase(id)
        refreshState()
    }

    public func notionDisconnect() {
        notionSync.disconnect()
        refreshState()
    }

    // Obsidian helpers
    public func setObsidianVault(_ url: URL) {
        do {
            try obsidianSync.pickVault(url)
        } catch {
            TKLog.obsidian.error("Vault set failed: \(error.localizedDescription)")
            obsidian = .error(error.localizedDescription)
        }
        refreshState()
    }

    public func clearObsidianVault() {
        obsidianSync.clear()
        refreshState()
    }
}
