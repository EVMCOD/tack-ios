import AppIntents
import Foundation

/// Quick add task from Siri / Shortcuts / Spotlight.
///
/// Voice examples (after AppShortcuts are registered):
///  - "Tack, add a new task 'Buy milk'"
///  - "Add to Tack: review PR #482"
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add task"
    static var description = IntentDescription("Adds a task to Tack from anywhere — Siri, Shortcuts, the share sheet.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Notes", default: "")
    var notes: String

    init() {}

    init(title: String, notes: String = "") {
        self.title = title
        self.notes = notes
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let t = TaskStore.shared.addTask(title: title, notes: notes)
        await IntegrationHub.shared.propagateToIntegrations(t)
        return .result(dialog: "Added \"\(t.title)\" to Tack.")
    }
}
