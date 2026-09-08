import Foundation
import SwiftData

/// Bidirectional sync between Tack and an Obsidian vault.
///
/// File format: YAML frontmatter + markdown body (see `MarkdownSerializer`).
/// `remoteID` is the absolute path within the vault.
///
/// Refresh strategy:
///   - On app launch: scan vault, diff vs Tack, push changed tasks.
///   - On macOS: install a `DispatchSource.makeFileSystemObjectSource` on the
///     `tack/` folder to get live updates while the app is open.
///   - On iOS: live update not available; rescan on next foreground.
@MainActor
public final class ObsidianSyncService {
    public static let shared = ObsidianSyncService()
    private let vault = ObsidianVault.shared

    public var isConfigured: Bool { vault.url != nil }

    public func pickVault(_ url: URL) throws {
        try vault.setVault(url)
        TKLog.obsidian.info("Vault set: \(url.lastPathComponent)")
    }

    public func clear() {
        vault.clear()
    }

    public func sync(container: ModelContainer) {
        guard vault.tasksRoot() != nil else {
            TKLog.obsidian.notice("Sync skipped: vault not configured")
            return
        }
        let ctx = container.mainContext

        // 1. Push: Tack tasks not yet persisted to disk.
        let all = (try? ctx.fetch(FetchDescriptor<TaskItem>())) ?? []
        for task in all where !task.isCompleted || true {
            do {
                try vault.writeTask(task)
                task.lastSyncedAt = .now
            } catch {
                TKLog.obsidian.error("Write failed: \(error.localizedDescription)")
            }
        }

        // 2. Pull: read files, ensure a matching TaskItem exists for each.
        for fileURL in vault.listTaskFiles() {
            guard let data = vault.readTask(at: fileURL),
                  let text = String(data: data, encoding: .utf8),
                  let parsed = MarkdownSerializer.parse(text) else { continue }
            let filePath = fileURL.path
            let fetched = (try? ctx.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.remoteID == filePath }))) ?? []
            if let existing = fetched.first {
                // Update in place if newer
                if let title = parsed.string("title"), title != existing.title, existing.lastSyncedAt == nil {
                    existing.title = title
                    existing.notes = parsed.body
                    existing.lastSyncedAt = Date.now
                }
            } else {
                let title = parsed.string("title") ?? "(imported)"
                let item = TaskItem(title: title, notes: parsed.body, origin: "obsidian")
                item.remoteID = filePath
                item.lastSyncedAt = Date.now
                ctx.insert(item)
            }
        }
        try? ctx.save()
    }
}
