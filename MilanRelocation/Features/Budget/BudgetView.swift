import SwiftUI

private enum BudgetSheet: Identifiable {
    case newExpense
    case editExpense(Expense)
    case targets
    case funding

    var id: String {
        switch self {
        case .newExpense: "new-expense"
        case .editExpense(let expense): "expense-\(expense.id.uuidString)"
        case .targets: "targets"
        case .funding: "funding"
        }
    }
}

struct BudgetView: View {
    @Environment(BudgetStore.self) private var budgetStore
    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var presentedSheet: BudgetSheet?

    private var monthExpenses: [Expense] { budgetStore.expenses(in: selectedMonth) }
    private var summary: MonthlyBudgetSummary { budgetStore.summary(for: selectedMonth) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(
                    eyebrow: "Milan finances",
                    title: "Budget",
                    detail: "Monthly targets, recorded expenses, and relocation reserves in euros."
                )

                if budgetStore.isLoading {
                    ContentStateView(kind: .loading, title: "Loading budget", detail: "Preparing local expense data.")
                        .accessibilityIdentifier("budget-loading-state")
                } else {
                    monthSelector

                    if let message = budgetStore.lastErrorMessage {
                        ContentStateView(kind: .error, title: "Local budget issue", detail: message)
                            .accessibilityIdentifier("budget-error-state")
                    }

                    summarySection
                    fundingSection
                    expensesSection
                    targetsSection
                }
            }
            .relocationPage()
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presentedSheet = .newExpense
                } label: {
                    Label("New expense", systemImage: "plus")
                }
                .accessibilityIdentifier("budget-add-expense")
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .newExpense:
                ExpenseEditorView(expense: nil).environment(budgetStore)
            case .editExpense(let expense):
                ExpenseEditorView(expense: expense).environment(budgetStore)
            case .targets:
                BudgetTargetsEditorView(targets: budgetStore.targets).environment(budgetStore)
            case .funding:
                FundingEditorView(funding: budgetStore.funding).environment(budgetStore)
            }
        }
    }

    private var monthSelector: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
                .accessibilityIdentifier("budget-previous-month")
            Spacer()
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(MRColor.ink)
                .accessibilityIdentifier("budget-month-label")
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
                .accessibilityIdentifier("budget-next-month")
        }
        .padding(.vertical, MRSpacing.xs)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            MetricGrid(columns: 3) {
                MetricBlock(label: "Plan", value: euro(summary.planned), detail: "monthly target", emphasized: true)
                MetricBlock(label: "Spent", value: euro(summary.actual), detail: "recorded this month")
                MetricBlock(
                    label: "Remaining",
                    value: euro(summary.remaining),
                    detail: summary.isOverBudget ? "over budget" : "available"
                )
            }
            .accessibilityIdentifier("budget-summary")

            if summary.isOverBudget {
                Label("Over budget by \(euro(summary.variance))", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MRColor.red)
                    .accessibilityIdentifier("budget-over-warning")
            } else {
                Text("\(euro(-summary.variance)) under the monthly plan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MRColor.success)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var fundingSection: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            SectionLabel(title: "Relocation funds", action: "Local balances")
            MetricGrid(columns: 3) {
                MetricBlock(label: "Cash", value: euro(budgetStore.funding.relocationCash), detail: "relocation fund")
                MetricBlock(label: "Deposits", value: euro(budgetStore.funding.deposits), detail: "set aside")
                MetricBlock(label: "Reserve", value: euro(budgetStore.funding.emergencyReserve), detail: "emergency only")
            }
            Button("Edit relocation funds") { presentedSheet = .funding }
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("budget-edit-funding")
        }
        .accessibilityIdentifier("budget-funding")
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            SectionLabel(title: "Expenses", action: "\(monthExpenses.count) this month")
            if monthExpenses.isEmpty {
                ContentStateView(
                    kind: .empty,
                    title: "No expenses this month",
                    detail: "Add a one-time expense or a recurring monthly cost."
                )
                .accessibilityIdentifier("budget-empty-expenses")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(monthExpenses) { expense in
                        Button {
                            presentedSheet = .editExpense(expense)
                        } label: {
                            ExpenseRow(expense: expense)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("budget-expense-\(expense.id.uuidString)")
                        Divider().overlay(MRColor.divider)
                    }
                }
                .accessibilityIdentifier("budget-expense-list")
            }
        }
    }

    private var targetsSection: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            HStack {
                SectionLabel(title: "Monthly targets")
                Button("Edit") { presentedSheet = .targets }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("budget-edit-targets")
            }

            ForEach(ExpenseCategory.allCases) { category in
                let target = budgetStore.target(for: category)
                let actual = budgetStore.actual(for: category, in: selectedMonth)
                let over = actual > target
                VStack(spacing: 7) {
                    HStack {
                        Text(category.rawValue).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(euro(actual)) / \(euro(target))")
                            .font(.caption)
                            .foregroundStyle(over ? MRColor.red : MRColor.secondaryText)
                    }
                    ProgressView(
                        value: decimalDouble(actual),
                        total: max(max(decimalDouble(target), decimalDouble(actual)), 1)
                    )
                    .tint(over ? MRColor.red : MRColor.accent)
                }
                .padding(.vertical, 7)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(category.rawValue), spent \(euro(actual)) of \(euro(target)) target\(over ? ", over budget" : "")")
            }
        }
        .accessibilityIdentifier("budget-category-targets")
    }

    private func shiftMonth(_ value: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) ?? selectedMonth
        }
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0 ... 2)))
    }

    private func decimalDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(alignment: .top, spacing: MRSpacing.md) {
            Image(systemName: expense.recurrence == .monthly ? "arrow.triangle.2.circlepath" : "receipt")
                .font(.body.weight(.semibold))
                .foregroundStyle(MRColor.accent)
                .frame(width: 28, height: 28)
                .background(MRColor.accentSoft, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MRColor.ink)
                Text("\(expense.category.rawValue) · \(expense.recurrence.rawValue)")
                    .font(.caption)
                    .foregroundStyle(MRColor.secondaryText)
                HStack(spacing: 8) {
                    Text(expense.owner.rawValue)
                    Text(expense.date.relocationShort)
                    if !expense.receipts.isEmpty {
                        Label("\(expense.receipts.count)", systemImage: "paperclip")
                    }
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(MRColor.secondaryText)
            }
            Spacer(minLength: 8)
            Text(expense.amount.formatted(.currency(code: "EUR").precision(.fractionLength(0 ... 2))))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MRColor.ink)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens expense editor")
    }

    private var accessibilitySummary: String {
        let receipts = expense.receipts.isEmpty ? "" : ", \(expense.receipts.count) receipt attachments"
        return "\(expense.name), \(expense.amount.formatted(.currency(code: "EUR"))), \(expense.category.rawValue), \(expense.recurrence.rawValue), owned by \(expense.owner.rawValue), dated \(expense.date.formatted(date: .long, time: .omitted))\(receipts)"
    }
}
