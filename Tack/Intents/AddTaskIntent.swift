import AppIntents
import Foundation

/// Quick add task from Siri / Shortcuts / Spotlight.
///
/// Voice examples (after AppShortcuts are registered):
///  - "Tack, add a new task 'Buy milk tomorrow 5pm'"
///  - "Add to Tack: review PR #482 in 3 days"
///  - "Capture in Tack: buy milk #groceries !high"
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add task"
    static var description = IntentDescription("Adds a task to Tack from anywhere — Siri, Shortcuts, the share sheet. Natural language is parsed for due dates, tags, and priority.")
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
        let parsed = NaturalLanguageParser.parse(title)
        let t = TaskStore.shared.addTask(
            title: parsed.cleanTitle.isEmpty ? "Untitled" : parsed.cleanTitle,
            notes: notes,
            dueAt: parsed.dueAt
        )
        await IntegrationHub.shared.propagateToIntegrations(t)
        return .result(dialog: "Added \"\(t.title)\" to Tack.")
    }
}
