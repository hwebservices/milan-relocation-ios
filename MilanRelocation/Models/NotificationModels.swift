import Foundation

enum NotificationPermissionStatus: String, CaseIterable, Identifiable {
    case notDetermined = "Not requested"
    case denied = "Denied"
    case authorized = "Allowed"
    case provisional = "Provisional"
    case ephemeral = "Temporary"

    var id: Self { self }
    var canSchedule: Bool { self == .authorized || self == .provisional || self == .ephemeral }
}

enum ReminderTiming: Int, Codable, CaseIterable, Identifiable {
    case sameDay = 0
    case oneDayBefore = 1
    case threeDaysBefore = 3
    case sevenDaysBefore = 7

    var id: Self { self }

    var title: String {
        switch self {
        case .sameDay: "Same day"
        case .oneDayBefore: "1 day before"
        case .threeDaysBefore: "3 days before"
        case .sevenDaysBefore: "7 days before"
        }
    }
}

enum NotificationCategory: String, Codable, CaseIterable, Identifiable {
    case taskDueDates
    case overdueTasks
    case housingFollowUps
    case documentExpirations
    case dailySummary
    case weeklyReview

    var id: Self { self }

    var title: String {
        switch self {
        case .taskDueDates: "Task due dates"
        case .overdueTasks: "Overdue tasks"
        case .housingFollowUps: "Housing follow-ups"
        case .documentExpirations: "Document expirations"
        case .dailySummary: "Daily unresolved summary"
        case .weeklyReview: "Weekly relocation review"
        }
    }

    var detail: String {
        switch self {
        case .taskDueDates: "Upcoming incomplete tasks"
        case .overdueTasks: "Incomplete tasks past their due date"
        case .housingFollowUps: "Scheduled and overdue apartment follow-ups"
        case .documentExpirations: "Documents approaching expiration"
        case .dailySummary: "A daily count of unresolved items"
        case .weeklyReview: "Monday planning reminder"
        }
    }
}

struct NotificationPreferences: Codable, Hashable {
    var enabledCategories: Set<NotificationCategory>
    var reminderTiming: ReminderTiming

    static let defaults = NotificationPreferences(
        enabledCategories: Set(NotificationCategory.allCases),
        reminderTiming: .oneDayBefore
    )

    func isEnabled(_ category: NotificationCategory) -> Bool {
        enabledCategories.contains(category)
    }

    var scheduleSignature: String {
        let categories = enabledCategories.map(\.rawValue).sorted().joined(separator: ",")
        return "\(categories)|\(reminderTiming.rawValue)"
    }
}

enum LocalNotificationTrigger: Hashable {
    case date(Date)
    case daily(hour: Int, minute: Int)
    case weekly(weekday: Int, hour: Int, minute: Int)
}

struct LocalNotificationRequest: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let trigger: LocalNotificationTrigger
}
