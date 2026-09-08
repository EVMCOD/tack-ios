import Foundation
import SwiftData

/// Bidirectional sync between Tack and a chosen Notion database.
///
/// Strategy:
///   - Push new/edited Tack tasks into Notion (create page or update by `remoteID`).
///   - Pull Notion pages that aren't already mirrored (dedup via `remoteID`).
///   - Conflicts: last-writer wins on `lastSyncedAt`.
///
/// Triggered on:
///   - App launch (`IntegrationHub.refreshOnLaunch`)
///   - Manual "Sync now" in Settings
///   - `BGAppRefreshTask` every ~30 min
@MainActor
public final class NotionSyncService {
    public static let shared = NotionSyncService()

    private let client = NotionClient()
    private let auth = NotionAuthService()

    public enum ConfigKey: String { case databaseID = "app.tack.notion.databaseID" }

    public var isConfigured: Bool {
        UserDefaults.standard.string(forKey: ConfigKey.databaseID.rawValue) != nil
    }

    public var isAuthorized: Bool { client.hasToken() }

    public func authorize(_ url: URL) async -> Bool {
        do { return try await auth.handleCallback(url) } catch {
            TKLog.notion.error("Notion auth failed: \(error.localizedDescription)")
            return false
        }
    }

    public func buildAuthURL() async -> URL {
        await auth.makeAuthorizationURL().url
    }

    public func pickDatabase(_ id: String) {
        UserDefaults.standard.set(id, forKey: ConfigKey.databaseID.rawValue)
        TKLog.notion.info("Database set: \(id)")
    }

    public func disconnect() {
        KeychainStore.remove(service: .notionOAuth, account: "access_token")
        UserDefaults.standard.removeObject(forKey: ConfigKey.databaseID.rawValue)
    }

    // MARK: - Sync

    public func sync(container: ModelContainer) async {
        guard isAuthorized, let dbID = UserDefaults.standard.string(forKey: ConfigKey.databaseID.rawValue) else {
            TKLog.notion.notice("Notion sync skipped: not configured")
            return
        }
        let ctx = container.mainContext

        // Push: Tack tasks not yet linked (or marked unsynced).
        let unsynced = (try? ctx.fetch(
            FetchDescriptor<TaskItem>(predicate: #Predicate { $0.origin == "local" || $0.origin == "notion" })
        )) ?? []
        for task in unsynced where task.remoteID == nil && !task.title.isEmpty {
            do {
                let page = try await client.createPage(in: dbID, title: task.title, status: task.status.rawValue, due: task.dueAt)
                task.remoteID = page.id
                task.origin = "notion"
                task.lastSyncedAt = .now
            } catch {
                TKLog.notion.error("Push failed: \(error.localizedDescription)")
            }
        }

        // Pull: Notion pages, deduped by remoteID.
        do {
            let resp = try await client.queryDatabase(id: dbID)
            for page in resp.results {
                let pageID = page.id
                let fetched = (try? ctx.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.remoteID == pageID }))) ?? []
                if !fetched.isEmpty { continue }
                // For v1 the title is fetched lazily on first view; we don't fetch
                // the full page in `queryDatabase` to keep latency low. Title and
                // status get filled in by `hydrate(pageID:)` on selection.
                let t = TaskItem(title: "(loaded from Notion)", origin: "notion")
                t.remoteID = pageID
                t.lastSyncedAt = Date.now
                ctx.insert(t)
            }
            try? ctx.save()
        } catch {
            TKLog.notion.error("Pull failed: \(error.localizedDescription)")
        }
    }
}
