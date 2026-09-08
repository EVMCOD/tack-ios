import WidgetKit
import SwiftUI

enum TaskWidgetKind: String {
    case today = "TodayWidget"
    case inbox = "InboxWidget"
}

// NOTE: TimelineProvider conformance triggers Swift 6 readiness warnings because
// WidgetKit calls these methods off the main actor while we need MainActor to
// fetch from ModelContext. In Swift 5 mode (active for this project) these are
// warnings; in Swift 6 they'd be errors. The fix when/if we migrate to Swift 6
// is to ship a pre-built JSON snapshot via App Group and read it from a
// nonisolated path instead. Tracked under v1.1.

struct TaskTimelineProvider: TimelineProvider {
    let todayOnly: Bool
    let displayName: String

    init(todayOnly: Bool, displayName: String) {
        self.todayOnly = todayOnly
        self.displayName = displayName
    }

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: .now,
            tasks: [
                WidgetTask(id: UUID(), title: "Review PR", listName: "Work", dueAt: .now, accentHex: "#5B8FF9"),
                WidgetTask(id: UUID(), title: "Buy groceries", listName: "Personal", dueAt: .now, accentHex: "#4ADE80")
            ]
        )
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(snapshotEntry())
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let now = Date.now
        let entry = TaskEntry(date: now, tasks: WidgetTaskLoader.tasks(todayOnly: todayOnly).map(WidgetTask.from))
        // Refresh at the next hour boundary. WidgetCenter.shared.reloadAllTimelines()
        // is also fired from the app after sync/change so refresh is responsive.
        let cal = Calendar.current
        let nextHour = cal.date(byAdding: .hour, value: 1, to: now)!
        let expiry = cal.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
        let timeline = Timeline(entries: [entry], policy: .after(expiry))
        completion(timeline)
    }

    @MainActor
    private func snapshotEntry() -> TaskEntry {
        TaskEntry(
            date: .now,
            tasks: Array(WidgetTaskLoader.tasks(todayOnly: todayOnly).prefix(5)).map(WidgetTask.from)
        )
    }
}
