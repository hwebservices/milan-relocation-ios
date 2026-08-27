import XCTest
@testable import MilanRelocation

@MainActor
final class BudgetStoreTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testExpenseCategoriesMatchApprovedList() {
        XCTAssertEqual(ExpenseCategory.allCases.map(\.rawValue), [
            "Rent", "Condominio", "Utilities", "Internet", "Groceries", "Transport",
            "Car Insurance", "Jeff’s Health Insurance", "Flights", "Moving", "Documents",
            "Tuition", "Other"
        ])
    }

    func testMonthlyTotalsCombineTargetsAndApplicableExpenses() {
        let store = makeStore(
            expenses: [
                expense(name: "Rent", amount: 900, date: date(2026, 7, 1), category: .rent, recurrence: .monthly),
                expense(name: "Food", amount: 100, date: date(2026, 8, 6), category: .groceries),
                expense(name: "Future", amount: 500, date: date(2026, 9, 1), category: .other)
            ],
            targets: [
                MonthlyBudgetTarget(category: .rent, amount: 1000),
                MonthlyBudgetTarget(category: .groceries, amount: 500)
            ]
        )

        let summary = store.summary(for: date(2026, 8, 1))

        XCTAssertEqual(summary.planned, 1500)
        XCTAssertEqual(summary.actual, 1000)
        XCTAssertEqual(summary.remaining, 500)
        XCTAssertEqual(summary.variance, -500)
        XCTAssertFalse(summary.isOverBudget)
    }

    func testRecurringExpensesApplyFromStartMonthForward() {
        let recurring = expense(name: "Internet", amount: 45, date: date(2027, 1, 12), category: .internet, recurrence: .monthly)
        let oneTime = expense(name: "Router", amount: 80, date: date(2027, 1, 12), category: .internet)
        let store = makeStore(expenses: [recurring, oneTime])

        XCTAssertTrue(store.expenses(in: date(2026, 12, 1)).isEmpty)
        XCTAssertEqual(Set(store.expenses(in: date(2027, 1, 1)).map(\.id)), Set([recurring.id, oneTime.id]))
        XCTAssertEqual(store.expenses(in: date(2027, 2, 1)).map(\.id), [recurring.id])
    }

    func testVarianceMarksOverBudgetMonth() {
        let store = makeStore(
            expenses: [expense(name: "Tuition", amount: 125, date: date(2026, 8, 2), category: .tuition)],
            targets: [MonthlyBudgetTarget(category: .tuition, amount: 100)]
        )

        let summary = store.summary(for: date(2026, 8, 1))

        XCTAssertTrue(summary.isOverBudget)
        XCTAssertEqual(summary.variance, 25)
        XCTAssertEqual(summary.remaining, -25)
    }

    func testExpenseMutationsAndFundingPersistAcrossRelaunch() {
        let persistence = MemoryBudgetPersistence()
        let store = BudgetStore(persistence: persistence, seedData: emptyData, calendar: calendar)
        var item = expense(name: "Flight", amount: 400, date: date(2026, 8, 1), category: .flights)
        store.create(item)
        item.amount = 450
        store.update(item)
        store.updateFunding(RelocationFunding(relocationCash: 10_000, deposits: 2_000, emergencyReserve: 5_000))

        let relaunched = BudgetStore(persistence: persistence, seedData: emptyData, calendar: calendar)

        XCTAssertEqual(relaunched.expenses.first?.amount, 450)
        XCTAssertEqual(relaunched.funding.emergencyReserve, 5_000)
        relaunched.delete(id: item.id)
        XCTAssertTrue(persistence.storedData?.expenses.isEmpty == true)
    }

    private var emptyData: BudgetData {
        BudgetData(
            expenses: [],
            targets: [],
            funding: RelocationFunding(relocationCash: 0, deposits: 0, emergencyReserve: 0)
        )
    }

    private func makeStore(
        expenses: [Expense] = [],
        targets: [MonthlyBudgetTarget] = []
    ) -> BudgetStore {
        BudgetStore(
            persistence: MemoryBudgetPersistence(),
            seedData: BudgetData(
                expenses: expenses,
                targets: targets,
                funding: RelocationFunding(relocationCash: 0, deposits: 0, emergencyReserve: 0)
            ),
            calendar: calendar
        )
    }

    private func expense(
        name: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory,
        recurrence: ExpenseRecurrence = .oneTime
    ) -> Expense {
        Expense(name: name, amount: amount, date: date, category: category, owner: .both, recurrence: recurrence)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

private final class MemoryBudgetPersistence: BudgetPersistence {
    var storedData: BudgetData?
    func load() throws -> BudgetData? { storedData }
    func save(_ data: BudgetData) throws { storedData = data }
}
