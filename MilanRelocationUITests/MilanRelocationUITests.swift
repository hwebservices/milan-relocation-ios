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

    func testAddsExpense() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToBudget(in: app)

        app.buttons["budget-add-expense"].tap()
        XCTAssertTrue(app.navigationBars["New Expense"].waitForExistence(timeout: 2))
        app.textFields["expense-name"].tap()
        app.textFields["expense-name"].typeText("Visa translation fee")
        app.textFields["expense-amount"].tap()
        app.textFields["expense-amount"].typeText("125.50")
        app.buttons["expense-save"].tap()

        let created = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Visa translation fee")
        ).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout: 3))
    }

    func testEditsExpenseRecurrence() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToBudget(in: app)

        let expense = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Groceries — Esselunga")
        ).firstMatch
        XCTAssertTrue(expense.waitForExistence(timeout: 3))
        expense.tap()
        XCTAssertTrue(app.navigationBars["Edit Expense"].waitForExistence(timeout: 2))
        app.segmentedControls.buttons["Monthly"].tap()
        app.buttons["expense-save"].tap()

        let edited = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Groceries — Esselunga", "Monthly")
        ).firstMatch
        XCTAssertTrue(edited.waitForExistence(timeout: 3))
    }

    func testCreatesHousingListing() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToHousing(in: app)

        app.buttons["housing-add-listing"].tap()
        XCTAssertTrue(app.navigationBars["New Listing"].waitForExistence(timeout: 2))
        app.textFields["housing-address"].tap()
        app.textFields["housing-address"].typeText("Via Torino 77")
        app.textFields["housing-neighborhood"].tap()
        app.textFields["housing-neighborhood"].typeText("Centro")
        let rent = app.textFields["housing-rent"]
        XCTAssertTrue(rent.waitForExistence(timeout: 2))
        rent.tap()
        rent.typeText("2100")
        app.buttons["housing-save-listing"].tap()

        let created = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Via Torino 77")).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout: 3))
    }

    func testEditsHousingListing() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToHousing(in: app)

        let listing = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Via Orti 12")).firstMatch
        XCTAssertTrue(listing.waitForExistence(timeout: 3))
        listing.tap()
        XCTAssertTrue(app.navigationBars["Edit Listing"].waitForExistence(timeout: 2))
        let address = app.textFields["housing-address"]
        address.tap()
        address.typeText(" Apt A")
        app.buttons["housing-save-listing"].tap()

        let edited = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Via Orti 12 Apt A")).firstMatch
        XCTAssertTrue(edited.waitForExistence(timeout: 3))
    }

    func testFiltersHousingListingsByStatus() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToHousing(in: app)

        app.buttons["housing-filter-button"].tap()
        XCTAssertTrue(app.navigationBars["Sort & Filter"].waitForExistence(timeout: 2))
        app.buttons["housing-filter-status"].tap()
        app.buttons["Over budget"].tap()
        app.buttons["housing-apply-filters"].tap()

        let overBudget = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Via Savona 31")).firstMatch
        let qualified = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Via Orti 12")).firstMatch
        XCTAssertTrue(overBudget.waitForExistence(timeout: 3))
        XCTAssertFalse(qualified.exists)
    }

    func testNotificationSettingsRequestsPermissionAndUpdatesPreferences() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToSettings(in: app)

        app.buttons["settings-notifications"].tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["notification-permission-status"].exists)
        app.buttons["notification-request-permission"].tap()

        let allowed = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "notification-permission-status", "Allowed")
        ).firstMatch
        XCTAssertTrue(allowed.waitForExistence(timeout: 3))

        app.buttons["notification-reminder-timing"].tap()
        app.buttons["3 days before"].tap()
        app.swipeUp()
        let housingToggle = app.switches["notification-category-housingFollowUps"]
        XCTAssertTrue(housingToggle.exists)
        housingToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let disabled = expectation(for: NSPredicate(format: "value == %@", "0"), evaluatedWith: housingToggle)
        wait(for: [disabled], timeout: 2)
    }

    func testNotificationSettingsHandlesDeniedPermission() {
        continueAfterFailure = false
        let app = makeApp()
        app.launchEnvironment["MILAN_NOTIFICATION_TEST_STATUS"] = "denied"
        app.launch()
        navigateToSettings(in: app)

        app.buttons["settings-notifications"].tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["notification-open-system-settings"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["notification-request-permission"].exists)
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["MILAN_UI_TESTING"] = "1"
        app.launchEnvironment["MILAN_RESET_TASKS"] = "1"
        app.launchEnvironment["MILAN_RESET_BUDGET"] = "1"
        app.launchEnvironment["MILAN_RESET_HOUSING"] = "1"
        app.launchEnvironment["MILAN_RESET_NOTIFICATIONS"] = "1"
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

    private func navigateToBudget(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-budget"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Budget"].waitForExistence(timeout: 2))
    }

    private func navigateToHousing(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-housing"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Housing"].waitForExistence(timeout: 2))
    }

    private func navigateToSettings(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-settings"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    private func openSidebar(from navigationBar: XCUIElement) {
        let sidebarButton = navigationBar.buttons["Milan"]
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 2), "Sidebar back button is unavailable")
        sidebarButton.tap()
    }
}
