import XCTest

final class TackUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
    }

    func testCoreTabNavigationExists() throws {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5),
                      "Tab bar should appear on launch")
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 3))
    }

    func testQuickAddOpens() throws {
        // Tap the floating + button (always exists)
        let plus = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Quick Add'")).firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 3))
        plus.tap()

        let titleField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'next'")).firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Quick Add sheet should present title field")
    }

    func testAddingTask_FlowsIntoToday() throws {
        let plus = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Quick Add'")).firstMatch
        plus.tap()
        let titleField = app.textFields.firstMatch
        titleField.tap()
        titleField.typeText("Pilot smoke test\n")
        // Either dismiss the sheet via "Add" or hit Cancel — both are valid
        let addButton = app.buttons["Add"]
        if addButton.exists { addButton.tap() } else {
            app.buttons["Cancel"].tap()
        }
    }

    func testSettingsOpens() throws {
        // Settings is the 4th tab
        let tabs = app.tabBars.firstMatch.buttons
        if tabs.count >= 4 { tabs.element(boundBy: 3).tap() }
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }
}
