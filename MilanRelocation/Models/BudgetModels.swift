import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case rent = "Rent"
    case condominio = "Condominio"
    case utilities = "Utilities"
    case internet = "Internet"
    case groceries = "Groceries"
    case transport = "Transport"
    case carInsurance = "Car Insurance"
    case jeffHealthInsurance = "Jeff’s Health Insurance"
    case flights = "Flights"
    case moving = "Moving"
    case documents = "Documents"
    case tuition = "Tuition"
    case other = "Other"

    var id: Self { self }
    var accessibilityID: String {
        switch self {
        case .rent: "rent"
        case .condominio: "condominio"
        case .utilities: "utilities"
        case .internet: "internet"
        case .groceries: "groceries"
        case .transport: "transport"
        case .carInsurance: "car-insurance"
        case .jeffHealthInsurance: "jeff-health-insurance"
        case .flights: "flights"
        case .moving: "moving"
        case .documents: "documents"
        case .tuition: "tuition"
        case .other: "other"
        }
    }
}

enum ExpenseRecurrence: String, Codable, CaseIterable, Identifiable {
    case oneTime = "One-time"
    case monthly = "Monthly"

    var id: Self { self }
}

struct ReceiptAttachment: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var localIdentifier: String
    var addedAt: Date

    init(id: UUID = UUID(), displayName: String, localIdentifier: String = UUID().uuidString, addedAt: Date = .now) {
        self.id = id
        self.displayName = displayName
        self.localIdentifier = localIdentifier
        self.addedAt = addedAt
    }
}

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var owner: TaskOwner
    var recurrence: ExpenseRecurrence
    var notes: String?
    var receipts: [ReceiptAttachment]

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory,
        owner: TaskOwner,
        recurrence: ExpenseRecurrence,
        notes: String? = nil,
        receipts: [ReceiptAttachment] = []
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.category = category
        self.owner = owner
        self.recurrence = recurrence
        self.notes = notes
        self.receipts = receipts
    }
}

struct MonthlyBudgetTarget: Identifiable, Codable, Hashable {
    var category: ExpenseCategory
    var amount: Decimal
    var id: ExpenseCategory { category }
}

struct RelocationFunding: Codable, Hashable {
    var relocationCash: Decimal
    var deposits: Decimal
    var emergencyReserve: Decimal
}

struct BudgetData: Codable, Hashable {
    var expenses: [Expense]
    var targets: [MonthlyBudgetTarget]
    var funding: RelocationFunding
}

struct MonthlyBudgetSummary: Equatable {
    let planned: Decimal
    let actual: Decimal

    var remaining: Decimal { planned - actual }
    var variance: Decimal { actual - planned }
    var isOverBudget: Bool { variance > 0 }
}
