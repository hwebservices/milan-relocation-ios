import Foundation

enum TaskOwner: String, Codable, CaseIterable, Identifiable {
    case henry = "Henry"
    case jeff = "Jeff"
    case both = "Both"

    var id: Self { self }
    var initials: String { self == .both ? "H+J" : String(rawValue.prefix(1)) }
}

struct RelocationTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var owner: TaskOwner
    var status: TaskStatus
    var dueDate: Date
    var notes: String?

    init(id: UUID = UUID(), title: String, category: String, owner: TaskOwner, status: TaskStatus, dueDate: Date, notes: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.owner = owner
        self.status = status
        self.dueDate = dueDate
        self.notes = notes
    }

    func isOverdue(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !status.isTerminal else { return false }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: referenceDate)
    }
}

struct TimelineItem: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let owner: TaskOwner
    let startDate: Date
    let endDate: Date
    let progress: Double
}

struct BudgetItem: Identifiable {
    let id = UUID()
    let category: String
    let planned: Decimal
    let actual: Decimal
}

struct DocumentItem: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let owner: TaskOwner
    let isReady: Bool
}

struct ContactItem: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let organization: String
    let email: String
}

