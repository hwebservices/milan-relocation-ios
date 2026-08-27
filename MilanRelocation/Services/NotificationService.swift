import Foundation
import Observation
import UserNotifications

protocol NotificationPreferencesPersistence: AnyObject {
    func load() -> NotificationPreferences?
    func save(_ preferences: NotificationPreferences)
}

final class UserDefaultsNotificationPreferencesPersistence: NotificationPreferencesPersistence {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "notification-preferences") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> NotificationPreferences? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(NotificationPreferences.self, from: data)
    }

    func save(_ preferences: NotificationPreferences) {
        defaults.set(try? JSONEncoder().encode(preferences), forKey: key)
    }

    func reset() { defaults.removeObject(forKey: key) }
}

@MainActor
protocol LocalNotificationCenterClient: AnyObject {
    func authorizationStatus() async -> NotificationPermissionStatus
    func requestAuthorization() async throws -> Bool
    func replacePendingRequests(with requests: [LocalNotificationRequest]) async throws
}

@MainActor
final class SystemLocalNotificationCenterClient: LocalNotificationCenterClient {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) { self.center = center }

    func authorizationStatus() async -> NotificationPermissionStatus {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        case .ephemeral: .ephemeral
        @unknown default: .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func replacePendingRequests(with requests: [LocalNotificationRequest]) async throws {
        center.removeAllPendingNotificationRequests()
        for request in requests {
            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.body
            content.sound = .default
            let trigger: UNNotificationTrigger
            switch request.trigger {
            case let .date(date):
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            case let .daily(hour, minute):
                trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
            case let .weekly(weekday, hour, minute):
                var components = DateComponents()
                components.weekday = weekday
                components.hour = hour
                components.minute = minute
                trigger = UNCalendarNotificationTrigger(
                    dateMatching: components, repeats: true
                )
            }
            try await center.add(UNNotificationRequest(identifier: request.id, content: content, trigger: trigger))
        }
    }
}

@MainActor
final class UITestLocalNotificationCenterClient: LocalNotificationCenterClient {
    private var status: NotificationPermissionStatus

    init(status: NotificationPermissionStatus = .notDetermined) { self.status = status }

    func authorizationStatus() async -> NotificationPermissionStatus { status }

    func requestAuthorization() async throws -> Bool {
        guard status != .denied else { return false }
        status = .authorized
        return true
    }

    func replacePendingRequests(with requests: [LocalNotificationRequest]) async throws {}
}

@MainActor
@Observable
final class NotificationService {
    private(set) var preferences: NotificationPreferences
    private(set) var permissionStatus: NotificationPermissionStatus = .notDetermined
    private(set) var scheduledCount = 0
    private(set) var lastErrorMessage: String?

    private let center: LocalNotificationCenterClient
    private let persistence: NotificationPreferencesPersistence
    private let calendar: Calendar

    init(
        center: LocalNotificationCenterClient,
        persistence: NotificationPreferencesPersistence,
        calendar: Calendar = .current
    ) {
        self.center = center
        self.persistence = persistence
        self.calendar = calendar
        preferences = persistence.load() ?? .defaults
    }

    static func live(environment: [String: String] = ProcessInfo.processInfo.environment) -> NotificationService {
        let isUITesting = environment["MILAN_UI_TESTING"] == "1"
        let key = isUITesting ? "ui-test-notification-preferences" : "notification-preferences"
        let persistence = UserDefaultsNotificationPreferencesPersistence(key: key)
        if environment["MILAN_RESET_NOTIFICATIONS"] == "1" { persistence.reset() }
        let testStatus: NotificationPermissionStatus = environment["MILAN_NOTIFICATION_TEST_STATUS"] == "denied"
            ? .denied : .notDetermined
        return NotificationService(
            center: isUITesting ? UITestLocalNotificationCenterClient(status: testStatus) : SystemLocalNotificationCenterClient(),
            persistence: persistence
        )
    }

    func refreshPermissionStatus() async {
        permissionStatus = await center.authorizationStatus()
    }

    func requestPermission() async {
        do {
            _ = try await center.requestAuthorization()
            permissionStatus = await center.authorizationStatus()
            lastErrorMessage = nil
        } catch {
            permissionStatus = await center.authorizationStatus()
            lastErrorMessage = "Notification permission could not be requested. You can try again in Settings."
        }
    }

    func setEnabled(_ isEnabled: Bool, for category: NotificationCategory) {
        if isEnabled { preferences.enabledCategories.insert(category) }
        else { preferences.enabledCategories.remove(category) }
        persistence.save(preferences)
    }

    func setReminderTiming(_ timing: ReminderTiming) {
        preferences.reminderTiming = timing
        persistence.save(preferences)
    }

    func rebuildScheduledNotifications(
        tasks: [RelocationTask],
        housingListings: [ApartmentListing],
        documents: [RelocationDocument],
        now: Date = .now
    ) async {
        await refreshPermissionStatus()
        let requests = permissionStatus.canSchedule
            ? notificationRequests(tasks: tasks, housingListings: housingListings, documents: documents, now: now)
            : []
        do {
            try await center.replacePendingRequests(with: requests)
            scheduledCount = requests.count
            lastErrorMessage = nil
        } catch {
            scheduledCount = 0
            lastErrorMessage = "Reminders could not be scheduled on this device."
        }
    }

    func notificationRequests(
        tasks: [RelocationTask],
        housingListings: [ApartmentListing],
        documents: [RelocationDocument],
        now: Date
    ) -> [LocalNotificationRequest] {
        var dated: [LocalNotificationRequest] = []
        let timing = preferences.reminderTiming

        if preferences.isEnabled(.taskDueDates) {
            for task in tasks where Self.isTaskDueReminderEligible(task, now: now, calendar: calendar) {
                let proposed = Self.reminderDate(for: task.dueDate, timing: timing, calendar: calendar)
                let fireDate = Self.nextAvailableDate(proposed: proposed, now: now, calendar: calendar)
                dated.append(LocalNotificationRequest(
                    id: "milan.task.due.\(task.id.uuidString)", title: "Task due soon",
                    body: "\(task.title) is due \(task.dueDate.formatted(date: .abbreviated, time: .omitted)).",
                    trigger: .date(fireDate)
                ))
            }
        }

        if preferences.isEnabled(.overdueTasks) {
            for task in tasks where Self.isOverdueTaskReminderEligible(task, now: now, calendar: calendar) {
                dated.append(LocalNotificationRequest(
                    id: "milan.task.overdue.\(task.id.uuidString)", title: "Task overdue",
                    body: "\(task.title) still needs attention.",
                    trigger: .date(Self.nextDailyOccurrence(after: now, hour: 9, calendar: calendar))
                ))
            }
        }

        if preferences.isEnabled(.housingFollowUps) {
            for listing in housingListings where Self.isHousingFollowUpReminderEligible(listing) {
                guard let followUpDate = listing.nextFollowUpDate else { continue }
                let proposed = Self.reminderDate(for: followUpDate, timing: timing, calendar: calendar)
                let fireDate = proposed > now ? proposed : Self.nextDailyOccurrence(after: now, hour: 9, calendar: calendar)
                dated.append(LocalNotificationRequest(
                    id: "milan.housing.followup.\(listing.id.uuidString)", title: proposed > now ? "Housing follow-up" : "Housing follow-up overdue",
                    body: "Follow up about \(listing.address) in \(listing.neighborhood).",
                    trigger: .date(fireDate)
                ))
            }
        }

        if preferences.isEnabled(.documentExpirations) {
            for document in documents where Self.isDocumentExpirationReminderEligible(document, now: now, calendar: calendar) {
                guard let expirationDate = document.expirationDate else { continue }
                let proposed = Self.reminderDate(for: expirationDate, timing: timing, calendar: calendar)
                dated.append(LocalNotificationRequest(
                    id: "milan.document.expiration.\(document.id.uuidString)", title: "Document expiration",
                    body: "\(document.name) expires \(expirationDate.formatted(date: .abbreviated, time: .omitted)).",
                    trigger: .date(Self.nextAvailableDate(proposed: proposed, now: now, calendar: calendar))
                ))
            }
        }

        dated.sort { Self.fireDate(of: $0) < Self.fireDate(of: $1) }
        var requests = Array(dated.prefix(62))
        let unresolvedCount = Self.unresolvedItemCount(
            tasks: tasks, housingListings: housingListings, documents: documents, now: now, calendar: calendar
        )
        if preferences.isEnabled(.dailySummary), unresolvedCount > 0 {
            requests.append(LocalNotificationRequest(
                id: "milan.summary.daily", title: "Milan relocation summary",
                body: "\(unresolvedCount) unresolved \(unresolvedCount == 1 ? "item needs" : "items need") attention today.",
                trigger: .daily(hour: 8, minute: 0)
            ))
        }
        if preferences.isEnabled(.weeklyReview) {
            requests.append(LocalNotificationRequest(
                id: "milan.review.weekly", title: "Weekly relocation review",
                body: "Review tasks, housing, documents, and next steps together.",
                trigger: .weekly(weekday: 2, hour: 18, minute: 0)
            ))
        }
        return requests
    }

    static func reminderDate(for targetDate: Date, timing: ReminderTiming, calendar: Calendar) -> Date {
        let targetDay = calendar.startOfDay(for: targetDate)
        let reminderDay = calendar.date(byAdding: .day, value: -timing.rawValue, to: targetDay) ?? targetDay
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: reminderDay) ?? reminderDay
    }

    static func isTaskDueReminderEligible(
        _ task: RelocationTask,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        !task.status.isTerminal
            && !task.isOverdue(referenceDate: now, calendar: calendar)
    }

    static func isOverdueTaskReminderEligible(_ task: RelocationTask, now: Date, calendar: Calendar) -> Bool {
        task.isOverdue(referenceDate: now, calendar: calendar)
    }

    static func isHousingFollowUpReminderEligible(_ listing: ApartmentListing) -> Bool {
        listing.qualification != .rejected && listing.nextFollowUpDate != nil
    }

    static func isDocumentExpirationReminderEligible(
        _ document: RelocationDocument,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard !document.isArchived,
              document.status != .notApplicable,
              document.status != .expired,
              let expirationDate = document.expirationDate
        else { return false }
        return expirationDate >= calendar.startOfDay(for: now)
    }

    static func unresolvedItemCount(
        tasks: [RelocationTask],
        housingListings: [ApartmentListing],
        documents: [RelocationDocument],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        tasks.filter { !$0.status.isTerminal }.count
            + housingListings.filter { $0.qualification != .rejected }.count
            + documents.filter {
                !$0.isArchived && !$0.effectiveStatus(referenceDate: now, calendar: calendar).isResolved
            }.count
    }

    static func nextDailyOccurrence(after now: Date, hour: Int, calendar: Calendar) -> Date {
        let today = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
        if today > now { return today }
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    static func nextAvailableDate(proposed: Date, now: Date, calendar: Calendar) -> Date {
        if proposed > now { return proposed }
        return calendar.date(byAdding: .minute, value: 1, to: now) ?? now.addingTimeInterval(60)
    }

    private static func fireDate(of request: LocalNotificationRequest) -> Date {
        if case let .date(date) = request.trigger { return date }
        return .distantFuture
    }
}
