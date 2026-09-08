import AppIntents
import Foundation

/// Quick capture — opens the app's QuickAdd sheet pre-populated with body text.
/// Use case: clipboard → capture, share sheet, Spotlight.
struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick capture"
    static var description = IntentDescription("Open Tack's capture sheet with prefilled text.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Body")
    var body: String

    init() {}
    init(body: String) { self.body = body }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Pending: write body to a UserDefaults handoff key, the app reads it
        // on launch and prefills QuickAddSheet.
        UserDefaults.standard.set(body, forKey: "app.tack.capture.payload")
        return .result()
    }
}
