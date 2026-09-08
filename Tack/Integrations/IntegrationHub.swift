import Foundation
import SwiftData
import SwiftUI

/// Coordinator for every external integration. App-level facade so views
/// never import the integration modules directly.
///
/// v1.0 ships with **Obsidian only** (vault folder + YAML-frontmatter MD).
/// Notion was planned but the user opted to defer it post-launch —
/// keep Notion-agnostic code paths so adding it back in v1.1 is mechanical.
@MainActor
public final class IntegrationHub: ObservableObject {
    public static let shared = IntegrationHub()

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

    private let obsidianSync = ObsidianSyncService.shared

    private init() {
        refreshState()
    }

    public func refreshState() {
        obsidian = obsidianSync.isConfigured ? .ok : .notConfigured
    }

    /// Called when the app becomes active.
    public func refreshOnLaunch() {
        Task { await syncAll() }
    }

    /// Hook for `BGTaskScheduler` in v1.1.
    public func scheduleBackgroundRefresh() {}

    /// Pull + push for every configured integration.
    public func syncAll() async {
        if obsidianSync.isConfigured {
            obsidian = .syncing
            obsidianSync.sync(container: TaskStore.shared.container)
            obsidian = obsidianSync.isConfigured ? .ok : .notConfigured
        }
        lastSync = .now
    }

    /// Called from QuickAdd when a new task is created locally — push only.
    public func propagateToIntegrations(_ task: TaskItem) async {
        if obsidianSync.isConfigured {
            obsidianSync.sync(container: TaskStore.shared.container)
        }
    }

    // MARK: - Obsidian

    public func setObsidianVault(_ url: URL) {
        do {
            try obsidianSync.pickVault(url)
            refreshState()
        } catch {
            TKLog.obsidian.error("Vault set failed: \(error.localizedDescription)")
            obsidian = .error(error.localizedDescription)
        }
    }

    public func clearObsidianVault() {
        obsidianSync.clear()
        refreshState()
    }
}
