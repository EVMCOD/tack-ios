import Foundation
import SwiftUI

/// Represents the user's chosen Obsidian vault folder. URL is stored as a
/// security-scoped bookmark in the keychain so the entitlement survives
/// across app launches and iOS re-installs.
public final class ObsidianVault: ObservableObject {
    public static let shared = ObsidianVault()

    @Published public private(set) var url: URL?

    private let bookmarkAccount = "vault_bookmark"

    public init() {
        restoreBookmark()
    }

    /// Sets (or replaces) the active vault folder. Stores a bookmark for future launches.
    public func setVault(_ url: URL) throws {
        let bookmark = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        KeychainStore.setData(bookmark, service: .vaultBookmark, account: bookmarkAccount)
        // Stop accessing any previous one
        self.url?.stopAccessingSecurityScopedResource()
        _ = url.startAccessingSecurityScopedResource()
        DispatchQueue.main.async { self.url = url }
    }

    public func clear() {
        KeychainStore.remove(service: .vaultBookmark, account: bookmarkAccount)
        url?.stopAccessingSecurityScopedResource()
        url = nil
    }

    private func restoreBookmark() {
        guard let data = KeychainStore.data(service: .vaultBookmark, account: bookmarkAccount) else { return }
        var stale = false
        if let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) {
            _ = url.startAccessingSecurityScopedResource()
            DispatchQueue.main.async { self.url = url }
        }
    }
}

// MARK: - File ops

extension ObsidianVault {
    /// Root folder for Tack-managed markdown files inside the vault.
    public func tasksRoot() -> URL? {
        guard let url else { return nil }
        let dir = url.appending(path: "tack")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public func listTaskFiles() -> [URL] {
        guard let root = tasksRoot(),
              let contents = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey])
        else { return [] }
        return contents.filter { $0.pathExtension == "md" }
    }

    public func readTask(at url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    public func writeTask(_ task: TaskItem) throws {
        guard let root = tasksRoot() else { return }
        let body = MarkdownSerializer.markdown(for: task)
        let filename = MarkdownSerializer.filename(for: task)
        let target = root.appending(path: filename)
        try body.data(using: .utf8)?.write(to: target, options: .atomic)
    }

    public func deleteTaskFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
