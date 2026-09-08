import Foundation
import SwiftData
import WidgetKit

/// Reads the shared SwiftData store. The main app writes to
/// `<AppGroup>/Tack.store`; the widget reads the same file.
///
/// Because both processes can have the SQLite store open at the same time,
/// we rely on SwiftData's WAL journaling to keep them consistent without
/// extra coordination. For bigger fish, a JSON snapshot is written under
/// `<AppGroup>/widget-snapshot.json` on every save (added in v1.1).
@MainActor
public enum WidgetTaskLoader {

    public static let groupID = "group.app.tack.shared"

    public static let container: ModelContainer = {
        let schema = Schema([TaskItem.self, TaskList.self, Tag.self])

        // Prefer App Group; fall back to tmpdir for sandbox scenarios.
        var storeURL = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: "TackWidget.store")
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            storeURL = group.appending(path: "Tack.store")
        }

        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Last-resort fallback so the widget process never crashes the home screen.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    public static func tasks(todayOnly: Bool) -> [TaskItem] {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let all = (try? ctx.fetch(descriptor)) ?? []
        let cal = Calendar.current
        return all.filter { task in
            if task.isCompleted { return false }
            if todayOnly {
                guard let d = task.dueAt else { return false }
                return cal.isDateInToday(d)
            }
            return true
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    public static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
