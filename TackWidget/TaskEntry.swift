import WidgetKit

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}

struct WidgetTask: Hashable, Identifiable {
    let id: UUID
    let title: String
    let listName: String
    let dueAt: Date?
    let accentHex: String?

    static func from(_ task: TaskItem) -> WidgetTask {
        WidgetTask(
            id: task.id,
            title: task.title,
            listName: task.listName,
            dueAt: task.dueAt,
            accentHex: task.list?.accentHex
        )
    }
}
