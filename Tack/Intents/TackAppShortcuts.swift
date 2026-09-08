import AppIntents

/// Surface these as system-wide voice commands via "Hey Siri".
struct TackAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add to \(.applicationName)",
                "\(.applicationName) add task",
                "Capture in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Complete in \(.applicationName)",
                "Mark done in \(.applicationName)"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: QuickCaptureIntent(),
            phrases: [
                "Open quick capture in \(.applicationName)",
                "\(.applicationName) capture"
            ],
            shortTitle: "Quick Capture",
            systemImageName: "square.and.pencil.circle.fill"
        )
    }

    /// Trigger an explicit refresh so the system sees phrases.
    static func updateAppShortcutParameters() {}
}
