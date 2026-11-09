import XCTest

/// On-device-style smoke checks for the main, user-visible flows.
final class RemorrowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // Test-only launch argument forces the visual guide to be visible.
        app.launchArguments.append("--remorrow-ui-guide")
        app.launch()
        return app
    }

    private func skipGuide(_ app: XCUIApplication) {
        let skip = app.buttons["welcomeSkip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 15))
        skip.tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 12))
    }

    func testFirstLaunchHasSkippableVisualGuide() {
        let app = launch()
        let next = app.buttons["welcomeContinue"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["welcomeSkip"].exists)
        next.tap()
        XCTAssertTrue(app.buttons["welcomeSkip"].exists)
        app.buttons["welcomeSkip"].tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 12))
    }

    func testReceiptsAndSubscriptionsCanBeReached() {
        let app = launch()
        skipGuide(app)
        app.tabBars.buttons["Receipts"].tap()
        XCTAssertTrue(app.buttons["Scan receipt"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["Add subscription"].exists)
    }

    func testPlansAndSearchCanBeReached() {
        let app = launch()
        skipGuide(app)
        let plans = app.tabBars.buttons["My plans"]
        XCTAssertTrue(plans.exists)
        plans.tap()
        XCTAssertTrue(app.staticTexts["My plans"].waitForExistence(timeout: 10))
        // Search is a real navigation destination, not a decorative icon.
        app.buttons["Search all saved memories"].tap()
        XCTAssertTrue(app.textFields["memorySearchField"].waitForExistence(timeout: 10))
    }

    func testSettingsHasWidgetPrivacyAndNotifications() {
        let app = launch()
        skipGuide(app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Show next item title in Home Screen widget"]
            .waitForExistence(timeout: 10))
        XCTAssertTrue(app.switches["Suggest earlier preparation alerts"].exists)
    }

    func testTodayHasOneCompactAgendaInsteadOfTwoRepeatedCards() {
        let app = launch()
        skipGuide(app)
        XCTAssertTrue(app.staticTexts["Your day"].waitForExistence(timeout: 12))
        // These were the two stacked headings in the old dashboard; the new
        // glance card consolidates both counts and actionable rows.
        XCTAssertFalse(app.staticTexts["YOUR DAILY BRIEFING"].exists)
        XCTAssertFalse(app.staticTexts["UP NEXT"].exists)
    }
}
