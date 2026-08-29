import Foundation
import Observation

protocol BudgetPersistence {
    func load() throws -> BudgetData?
    func save(_ data: BudgetData) throws
}

struct FileBudgetPersistence: BudgetPersistence {
    let url: URL

    func load() throws -> BudgetData? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(BudgetData.self, from: Data(contentsOf: url))
    }

    func save(_ data: BudgetData) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(data).write(to: url, options: .atomic)
    }

    static func appStorage(environment: [String: String] = ProcessInfo.processInfo.environment) -> FileBudgetPersistence {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let isUITesting = environment["MILAN_UI_TESTING"] == "1"
        return FileBudgetPersistence(url: directory.appendingPathComponent(isUITesting ? "ui-test-budget.json" : "budget.json"))
    }
}

@MainActor
@Observable
final class BudgetStore {
    private(set) var data: BudgetData
    private(set) var isLoading = true
    private(set) var lastErrorMessage: String?

    private let persistence: BudgetPersistence
    private let calendar: Calendar

    init(persistence: BudgetPersistence, seedData: BudgetData, calendar: Calendar = .current) {
        self.persistence = persistence
        self.calendar = calendar
        do {
            if let savedData = try persistence.load() {
                data = savedData
            } else {
                data = seedData
                try persistence.save(seedData)
            }
        } catch {
            data = seedData
            lastErrorMessage = "Budget data could not be loaded. Your changes may not persist."
        }
        normalizeTargets()
        sortExpenses()
        isLoading = false
    }

    static func live(
        calendar: Calendar = .current,
        now: Date = .now,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> BudgetStore {
        let persistence = FileBudgetPersistence.appStorage(environment: environment)
        if environment["MILAN_RESET_BUDGET"] == "1" {
            try? FileManager.default.removeItem(at: persistence.url)
        }
        let seed = environment["MILAN_UI_TESTING"] == "1"
            ? sampleData(calendar: calendar, now: now)
            : BudgetData(expenses: [], targets: [], funding: RelocationFunding(relocationCash: 0, deposits: 0, emergencyReserve: 0))
        return BudgetStore(
            persistence: persistence,
            seedData: seed,
            calendar: calendar
        )
    }

    var expenses: [Expense] { data.expenses }
    var targets: [MonthlyBudgetTarget] { data.targets }
    var funding: RelocationFunding { data.funding }

    func create(_ expense: Expense) {
        data.expenses.append(expense)
        commit()
    }

    func update(_ expense: Expense) {
        guard let index = data.expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        data.expenses[index] = expense
        commit()
    }

    func delete(id: UUID) {
        data.expenses.removeAll { $0.id == id }
        commit()
    }

    func updateTargets(_ targets: [MonthlyBudgetTarget]) {
        data.targets = targets
        normalizeTargets()
        commit()
    }

    func updateFunding(_ funding: RelocationFunding) {
        data.funding = funding
        commit()
    }

    func replaceAll(with data: BudgetData) { self.data = data; normalizeTargets(); commit() }

    func expenses(in month: Date) -> [Expense] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return data.expenses.filter { expense in
            switch expense.recurrence {
            case .oneTime:
                return expense.date >= monthInterval.start && expense.date < monthInterval.end
            case .monthly:
                return expense.date < monthInterval.end
            }
        }
    }

    func target(for category: ExpenseCategory) -> Decimal {
        data.targets.first(where: { $0.category == category })?.amount ?? 0
    }

    func actual(for category: ExpenseCategory, in month: Date) -> Decimal {
        expenses(in: month)
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }

    func summary(for month: Date) -> MonthlyBudgetSummary {
        let planned = data.targets.reduce(0) { $0 + $1.amount }
        let actual = expenses(in: month).reduce(0) { $0 + $1.amount }
        return MonthlyBudgetSummary(planned: planned, actual: actual)
    }

    private func commit() {
        sortExpenses()
        do {
            try persistence.save(data)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Budget changes could not be saved. Please try again."
        }
    }

    private func normalizeTargets() {
        let existing = Dictionary(uniqueKeysWithValues: data.targets.map { ($0.category, $0.amount) })
        data.targets = ExpenseCategory.allCases.map {
            MonthlyBudgetTarget(category: $0, amount: existing[$0] ?? 0)
        }
    }

    private func sortExpenses() {
        data.expenses.sort {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    static func sampleData(calendar: Calendar = .current, now: Date = .now) -> BudgetData {
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        func day(_ value: Int) -> Date { calendar.date(byAdding: .day, value: value - 1, to: monthStart) ?? now }
        func month(_ offset: Int, day value: Int) -> Date {
            let shifted = calendar.date(byAdding: .month, value: offset, to: monthStart) ?? monthStart
            return calendar.date(byAdding: .day, value: value - 1, to: shifted) ?? shifted
        }

        let targets: [(ExpenseCategory, Decimal)] = [
            (.rent, 3200), (.condominio, 350), (.utilities, 180), (.internet, 45),
            (.groceries, 850), (.transport, 180), (.carInsurance, 120),
            (.jeffHealthInsurance, 430), (.flights, 0), (.moving, 0),
            (.documents, 0), (.tuition, 700), (.other, 300)
        ]

        return BudgetData(
            expenses: [
                Expense(name: "Porta Romana temporary rent", amount: 2850, date: month(-1, day: 1), category: .rent, owner: .both, recurrence: .monthly, notes: "Includes furnished apartment service fee."),
                Expense(name: "Jeff health coverage", amount: 420, date: month(-2, day: 3), category: .jeffHealthInsurance, owner: .jeff, recurrence: .monthly),
                Expense(name: "Fiber internet", amount: 39.99, date: month(-1, day: 8), category: .internet, owner: .henry, recurrence: .monthly),
                Expense(name: "Groceries — Esselunga", amount: 164.35, date: day(6), category: .groceries, owner: .jeff, recurrence: .oneTime),
                Expense(name: "ATM transit passes", amount: 78, date: day(4), category: .transport, owner: .both, recurrence: .oneTime)
            ],
            targets: targets.map { MonthlyBudgetTarget(category: $0.0, amount: $0.1) },
            funding: RelocationFunding(relocationCash: 45000, deposits: 8000, emergencyReserve: 20000)
        )
    }
}
