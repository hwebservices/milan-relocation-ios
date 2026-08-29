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

    func testCreatesDocument() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToDocuments(in: app)

        app.buttons["documents-add-document"].tap()
        XCTAssertTrue(app.navigationBars["New Document"].waitForExistence(timeout: 2))
        let name = app.textFields["document-name"]
        name.tap()
        name.typeText("Italian tax code certificate")
        app.buttons["document-save"].tap()

        let created = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Italian tax code certificate")
        ).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout: 3))
    }

    func testEditsDocument() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToDocuments(in: app)

        let document = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Apostilled marriage certificate")
        ).firstMatch
        XCTAssertTrue(document.waitForExistence(timeout: 3))
        document.tap()
        XCTAssertTrue(app.navigationBars["Edit Document"].waitForExistence(timeout: 2))

        let name = app.textFields["document-name"]
        name.tap()
        name.typeText(" — certified")
        app.buttons["document-save"].tap()

        let edited = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Apostilled marriage certificate — certified")
        ).firstMatch
        XCTAssertTrue(edited.waitForExistence(timeout: 3))
    }

    func testFiltersDocumentsByStatus() {
        continueAfterFailure = false
        let app = makeApp()
        app.launch()
        navigateToDocuments(in: app)

        app.buttons["document-filter-button"].tap()
        XCTAssertTrue(app.navigationBars["Document Filters"].waitForExistence(timeout: 2))
        app.buttons["document-filter-status"].tap()
        app.buttons["Requested"].tap()
        app.buttons["document-apply-filters"].tap()

        let requested = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Apostilled marriage certificate")
        ).firstMatch
        let complete = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Henry passport")
        ).firstMatch
        XCTAssertTrue(requested.waitForExistence(timeout: 3))
        XCTAssertFalse(complete.exists)
    }

    func testCreatesAndEditsContact() {
        continueAfterFailure = false
        let app = makeApp(); app.launch(); navigateToContacts(in: app)
        app.buttons["contacts-add-contact"].tap()
        XCTAssertTrue(app.navigationBars["New Contact"].waitForExistence(timeout: 2))
        app.textFields["contact-name"].tap(); app.textFields["contact-name"].typeText("Paolo Verdi")
        app.textFields["contact-role"].tap(); app.textFields["contact-role"].typeText("Accountant")
        app.textFields["contact-email"].tap(); app.textFields["contact-email"].typeText("paolo@example.com")
        app.buttons["contact-save"].tap()
        let created = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Paolo Verdi")).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout: 3)); created.tap()
        XCTAssertTrue(app.navigationBars["Edit Contact"].waitForExistence(timeout: 2))
        let organization = app.textFields["contact-organization"]; organization.tap(); organization.typeText("Studio Verdi")
        app.buttons["contact-save"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Studio Verdi")).firstMatch.waitForExistence(timeout: 3))
    }

    func testSavesAndEditsWeeklyReview() {
        continueAfterFailure = false
        let app = makeApp(); app.launch(); navigateToWeeklyReview(in: app)
        app.buttons["review-add"].tap()
        XCTAssertTrue(app.navigationBars["New Review"].waitForExistence(timeout: 2))
        app.textViews["review-progress"].tap(); app.textViews["review-progress"].typeText("Submitted residency packet")
        app.textViews["review-priorities"].tap(); app.textViews["review-priorities"].typeText("Choose apartment")
        app.buttons["review-save"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Submitted residency packet")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3)); row.tap()
        XCTAssertTrue(app.navigationBars["Edit Review"].waitForExistence(timeout: 2))
    }

    func testShowCompletedSettingControlsTaskList() {
        continueAfterFailure = false
        let app = makeApp(); app.launch(); navigateToSettings(in: app)
        let toggle = app.switches["settings-show-completed"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2)); toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        openSidebar(from: app.navigationBars["Settings"])
        app.staticTexts["nav-tasks"].tap()
        XCTAssertTrue(app.navigationBars["Tasks"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Create first-month arrival budget")).firstMatch.exists)
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
        app.launchEnvironment["MILAN_RESET_DOCUMENTS"] = "1"
        app.launchEnvironment["MILAN_RESET_NOTIFICATIONS"] = "1"
        app.launchEnvironment["MILAN_RESET_CONTACTS"] = "1"
        app.launchEnvironment["MILAN_RESET_WEEKLY_REVIEWS"] = "1"
        app.launchEnvironment["MILAN_RESET_SETTINGS"] = "1"
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

    private func navigateToDocuments(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-documents"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Documents"].waitForExistence(timeout: 2))
    }

    private func navigateToSettings(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5))
        openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-settings"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    private func navigateToContacts(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5)); openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-contacts"]; XCTAssertTrue(row.waitForExistence(timeout: 2)); row.tap()
        XCTAssertTrue(app.navigationBars["Contacts"].waitForExistence(timeout: 2))
    }

    private func navigateToWeeklyReview(in app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 5)); openSidebar(from: app.navigationBars["Today"])
        let row = app.staticTexts["nav-weeklyReview"]; XCTAssertTrue(row.waitForExistence(timeout: 2)); row.tap()
        XCTAssertTrue(app.navigationBars["Weekly Review"].waitForExistence(timeout: 2))
    }

    private func openSidebar(from navigationBar: XCUIElement) {
        let sidebarButton = navigationBar.buttons["Milan"]
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 2), "Sidebar back button is unavailable")
        sidebarButton.tap()
    }
}
