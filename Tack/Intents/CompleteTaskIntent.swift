import AppIntents
import Foundation

/// Mark a specific task complete. Used by both Shortcuts and the interactive
/// widget (where the widget config intent supplies the task id).
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete task"
    static var description = IntentDescription("Marks a Tack task as done.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task title")
    var title: String

    init() {}
    init(title: String) { self.title = title }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let match = TaskStore.shared.tasks.first(where: { $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame }) else {
            return .result(dialog: "Couldn't find a task with the title \"\(title)\".")
        }
        TaskStore.shared.toggleComplete(match)
        return .result(dialog: "Done: \(match.title)")
    }
}

/// Returns the most recent N open tasks — used by the widget configuration intent
/// and by Shortcuts when the user wants to query Tack.
struct OpenTasksQuery: EntityQuery {
    @MainActor
    private static func all() -> [TaskItem] { TaskStore.shared.tasks }

    func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        let all = await Self.all()
        return all.filter { identifiers.contains($0.id) }.map { TaskEntity(id: $0.id, title: $0.title) }
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        let all = await Self.all()
        return all
            .filter { !$0.isCompleted }
            .prefix(20)
            .map { TaskEntity(id: $0.id, title: $0.title) }
    }
}

struct TaskEntity: AppEntity, Identifiable, Sendable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task")
    static var defaultQuery = OpenTasksQuery()

    var id: UUID
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}
