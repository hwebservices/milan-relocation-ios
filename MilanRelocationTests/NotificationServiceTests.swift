import XCTest
@testable import MilanRelocation

@MainActor
final class NotificationServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testReminderDateCalculationsForEveryTiming() {
        let target = date(2027, 1, 15, hour: 16)

        XCTAssertEqual(NotificationService.reminderDate(for: target, timing: .sameDay, calendar: calendar), date(2027, 1, 15, hour: 9))
        XCTAssertEqual(NotificationService.reminderDate(for: target, timing: .oneDayBefore, calendar: calendar), date(2027, 1, 14, hour: 9))
        XCTAssertEqual(NotificationService.reminderDate(for: target, timing: .threeDaysBefore, calendar: calendar), date(2027, 1, 12, hour: 9))
        XCTAssertEqual(NotificationService.reminderDate(for: target, timing: .sevenDaysBefore, calendar: calendar), date(2027, 1, 8, hour: 9))
    }

    func testMissedReminderWindowUsesNextSafeMinute() {
        let now = date(2026, 8, 27, hour: 14)
        let proposed = date(2026, 8, 20, hour: 9)

        XCTAssertEqual(
            NotificationService.nextAvailableDate(proposed: proposed, now: now, calendar: calendar),
            date(2026, 8, 27, hour: 14, minute: 1)
        )
    }

    func testTaskEligibilityExcludesCompletedAndSeparatesOverdueTasks() {
        let now = date(2026, 8, 27, hour: 8)
        var upcoming = task(status: .inProgress, dueDate: date(2026, 8, 28))

        XCTAssertTrue(NotificationService.isTaskDueReminderEligible(upcoming, now: now, calendar: calendar))
        XCTAssertFalse(NotificationService.isOverdueTaskReminderEligible(upcoming, now: now, calendar: calendar))

        upcoming.status = .complete
        XCTAssertFalse(NotificationService.isTaskDueReminderEligible(upcoming, now: now, calendar: calendar))
        upcoming.status = .inProgress
        upcoming.dueDate = date(2026, 8, 26)
        XCTAssertFalse(NotificationService.isTaskDueReminderEligible(upcoming, now: now, calendar: calendar))
        XCTAssertTrue(NotificationService.isOverdueTaskReminderEligible(upcoming, now: now, calendar: calendar))
    }

    func testHousingAndDocumentEligibility() {
        let now = date(2026, 8, 27, hour: 8)
        var listing = ApartmentListing(address: "Via Orti 12", neighborhood: "Porta Romana", rent: 1_800)
        XCTAssertFalse(NotificationService.isHousingFollowUpReminderEligible(listing))
        listing.nextFollowUpDate = date(2026, 8, 28)
        XCTAssertTrue(NotificationService.isHousingFollowUpReminderEligible(listing))
        listing.qualification = .rejected
        XCTAssertFalse(NotificationService.isHousingFollowUpReminderEligible(listing))

        let currentDocument = DocumentItem(name: "Passport", category: "Identity", owner: .both, isReady: true, expirationDate: date(2027, 1, 1))
        let expiredDocument = DocumentItem(name: "Old permit", category: "Identity", owner: .henry, isReady: true, expirationDate: date(2026, 8, 26))
        let undatedDocument = DocumentItem(name: "Certificate", category: "Civil", owner: .both, isReady: false)
        XCTAssertTrue(NotificationService.isDocumentExpirationReminderEligible(currentDocument, now: now, calendar: calendar))
        XCTAssertFalse(NotificationService.isDocumentExpirationReminderEligible(expiredDocument, now: now, calendar: calendar))
        XCTAssertFalse(NotificationService.isDocumentExpirationReminderEligible(undatedDocument, now: now, calendar: calendar))
    }

    func testDisabledCategoryRemovesItsRequests() {
        let service = makeService()
        service.setEnabled(false, for: .taskDueDates)
        let requests = service.notificationRequests(
            tasks: [task(status: .inProgress, dueDate: date(2026, 8, 30))],
            housingListings: [], documents: [], now: date(2026, 8, 27, hour: 8)
        )

        XCTAssertFalse(requests.contains { $0.id.hasPrefix("milan.task.due.") })
        XCTAssertTrue(requests.contains { $0.id == "milan.summary.daily" })
        XCTAssertTrue(requests.contains { $0.id == "milan.review.weekly" })
    }

    func testRebuildReplacesRescheduledAndCompletedTaskNotifications() async {
        let center = RecordingNotificationCenter()
        let service = NotificationService(center: center, persistence: MemoryNotificationPreferencesPersistence(), calendar: calendar)
        let now = date(2026, 8, 27, hour: 8)
        var item = task(status: .inProgress, dueDate: date(2026, 8, 30))

        await service.rebuildScheduledNotifications(tasks: [item], housingListings: [], documents: [], now: now)
        let original = center.requests.first { $0.id.hasPrefix("milan.task.due.") }
        XCTAssertNotNil(original)

        item.dueDate = date(2026, 9, 3)
        await service.rebuildScheduledNotifications(tasks: [item], housingListings: [], documents: [], now: now)
        let rescheduled = center.requests.first { $0.id.hasPrefix("milan.task.due.") }
        XCTAssertNotEqual(original?.trigger, rescheduled?.trigger)

        item.status = .complete
        await service.rebuildScheduledNotifications(tasks: [item], housingListings: [], documents: [], now: now)
        XCTAssertFalse(center.requests.contains { $0.id.hasPrefix("milan.task.") })
        XCTAssertEqual(center.replacementCount, 3)
    }

    private func makeService() -> NotificationService {
        NotificationService(
            center: RecordingNotificationCenter(),
            persistence: MemoryNotificationPreferencesPersistence(),
            calendar: calendar
        )
    }

    private func task(status: TaskStatus, dueDate: Date) -> RelocationTask {
        RelocationTask(title: "Test task", category: "Admin", owner: .both, status: status, dueDate: dueDate)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

@MainActor
private final class RecordingNotificationCenter: LocalNotificationCenterClient {
    var requests: [LocalNotificationRequest] = []
    var replacementCount = 0
    func authorizationStatus() async -> NotificationPermissionStatus { .authorized }
    func requestAuthorization() async throws -> Bool { true }
    func replacePendingRequests(with requests: [LocalNotificationRequest]) async throws {
        self.requests = requests
        replacementCount += 1
    }
}

private final class MemoryNotificationPreferencesPersistence: NotificationPreferencesPersistence {
    var preferences: NotificationPreferences?
    func load() -> NotificationPreferences? { preferences }
    func save(_ preferences: NotificationPreferences) { self.preferences = preferences }
}
