import XCTest

/// App Store screenshot capture.
///
/// Deliberately does NOT touch app source: onboarding is skipped through a
/// UserDefaults launch argument and the demo content seeds itself on first
/// launch, so the build under test is byte-identical to the shipped one.
final class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-app.tack.hasOnboarded", "YES",
            "-AppleLanguages", "(\(ProcessInfo.processInfo.environment["SCREENSHOT_LANG"] ?? "en"))",
            "-AppleLocale", ProcessInfo.processInfo.environment["SCREENSHOT_LOCALE"] ?? "en_US",
        ]
        app.launch()
    }

    /// `XCUIScreen.main.screenshot()` grabs whatever is on screen — not
    /// necessarily this app. Assert foreground first or a green test can ship
    /// screenshots of a different app entirely.
    private func capture(_ name: String) {
        XCTAssertEqual(app.state, .runningForeground, "app lost foreground before \(name)")
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    private func tapTab(_ index: Int) {
        let tabs = app.tabBars.firstMatch.buttons
        guard tabs.count > index else { return XCTFail("tab \(index) missing (\(tabs.count) tabs)") }
        tabs.element(boundBy: index).tap()
        _ = app.wait(for: .runningForeground, timeout: 2)
        Thread.sleep(forTimeInterval: 0.8)   // let the spring animations settle
    }

    func testCaptureAppStoreScreenshots() throws {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "tab bar never appeared")
        Thread.sleep(forTimeInterval: 1.5)

        tapTab(0); capture("01_today")
        tapTab(1); capture("02_inbox")
        tapTab(2); capture("03_lists")
        tapTab(3); capture("04_stats")

        // Quick Add sheet — dismissed by its own button, never by a swipe:
        // an edge drag opens Notification Centre or switches apps.
        tapTab(0)
        let plus = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Quick Add'")).firstMatch
        if plus.waitForExistence(timeout: 3) {
            plus.tap()
            Thread.sleep(forTimeInterval: 1.2)
            // iOS shows a one-off keyboard tutorial ("Type English and Spanish",
            // continuous-path intro…) over the sheet. It is not part of the app
            // and must never reach the App Store listing.
            let cont = app.buttons["Continue"]
            if cont.waitForExistence(timeout: 2) { cont.tap(); Thread.sleep(forTimeInterval: 1.0) }
            capture("05_quickadd")
            for label in ["Cancel", "Cancelar", "Annuler", "Abbrechen", "Annulla"] {
                if app.buttons[label].exists { app.buttons[label].tap(); break }
            }
        }

        tapTab(4); capture("06_settings")
    }
}
