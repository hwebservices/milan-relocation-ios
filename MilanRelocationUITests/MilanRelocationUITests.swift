import XCTest

@MainActor
final class MilanRelocationUITests: XCTestCase {
    func testTodayIsDefaultAndShowsCommandCenterContent() {
        continueAfterFailure = false
        let app = makeApp()
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
        let app = makeApp()
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

    func testCreatesTask() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToTasks(in: app)

        app.buttons["tasks-add-task"].tap()
        XCTAssertTrue(app.navigationBars["New Task"].waitForExistence(timeout: 2))
        let titleField = app.textFields["task-title"]
        titleField.tap()
        titleField.typeText("Arrange pet travel")
        app.buttons["task-save"].tap()

        let createdTask = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Arrange pet travel")).firstMatch
        XCTAssertTrue(createdTask.waitForExistence(timeout: 3))
    }

    func testEditsTaskStatus() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToTasks(in: app)

        let task = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Confirm temporary apartment")).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: 3))
        task.tap()
        XCTAssertTrue(app.navigationBars["Edit Task"].waitForExistence(timeout: 2))

        app.descendants(matching: .any)["task-status"].tap()
        app.collectionViews.buttons["Complete"].firstMatch.tap()
        app.buttons["task-save"].tap()

        let editedTask = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Confirm temporary apartment", "Complete")).firstMatch
        XCTAssertTrue(editedTask.waitForExistence(timeout: 3))
    }

    func testTimelineNavigationShowsLiveGantt() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToTimeline(in: app)

        XCTAssertTrue(app.descendants(matching: .any)["timeline-mode-picker"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["timeline-chart"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["timeline-move-milestone"].exists)
    }

    func testTimelineOpensTaskEditor() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToTimeline(in: app)

        let taskBar = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Confirm temporary apartment")
        ).firstMatch
        XCTAssertTrue(taskBar.waitForExistence(timeout: 3))
        taskBar.tap()

        XCTAssertTrue(app.navigationBars["Edit Task"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.textFields["task-title"].value as? String, "Confirm temporary apartment in Porta Romana")
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["MILAN_UI_TESTING"] = "1"
        app.launchEnvironment["MILAN_RESET_TASKS"] = "1"
        return app
    }

    private func navigateToTasks(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-tasks"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Tasks"].waitForExistence(timeout: 2))
    }

    private func navigateToTimeline(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-timeline"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Timeline"].waitForExistence(timeout: 2))
    }

    private func openSidebar(from navigationBar: XCUIElement) {
        let sidebarButton = navigationBar.buttons["Milan"]
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 2), "Sidebar back button is unavailable")
        sidebarButton.tap()
    }
}
