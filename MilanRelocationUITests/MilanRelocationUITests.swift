import XCTest

@MainActor
final class MilanRelocationUITests: XCTestCase {
    func testTodayIsDefaultAndShowsCommandCenterContent() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["today-command-center"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["today-metrics"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["today-up-next"].exists)

        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["today-current-focus"].waitForExistence(timeout: 2))
    }

    func testMainNavigationReachesEveryScreen() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let destinations: [(id: String, title: String)] = [
            ("tasks", "Tasks"),
            ("timeline", "Timeline"),
            ("budget", "Budget"),
            ("housing", "Housing"),
            ("educationWork", "Education & Work"),
            ("documents", "Documents"),
            ("contacts", "Contacts"),
            ("weeklyReview", "Weekly Review"),
            ("settings", "Settings"),
            ("today", "Today")
        ]

        for destination in destinations {
            openSidebar(from: app.navigationBars.element(boundBy: 0))
            let row = app.staticTexts["nav-\(destination.id)"]
            XCTAssertTrue(row.waitForExistence(timeout: 2), "Missing navigation row for \(destination.title)")
            row.tap()
            XCTAssertTrue(app.navigationBars[destination.title].waitForExistence(timeout: 2), "Did not navigate to \(destination.title)")
        }
    }

    private func openSidebar(from navigationBar: XCUIElement) {
        let sidebarButton = navigationBar.buttons["Milan"]
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 2), "Sidebar back button is unavailable")
        sidebarButton.tap()
    }
}
