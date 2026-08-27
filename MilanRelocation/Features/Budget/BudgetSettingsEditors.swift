import SwiftUI

struct BudgetTargetsEditorView: View {
    @Environment(BudgetStore.self) private var budgetStore
    @Environment(\.dismiss) private var dismiss
    @State private var amounts: [ExpenseCategory: String]

    init(targets: [MonthlyBudgetTarget]) {
        _amounts = State(initialValue: Dictionary(uniqueKeysWithValues: targets.map {
            ($0.category, NSDecimalNumber(decimal: $0.amount).stringValue)
        }))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(ExpenseCategory.allCases) { category in
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            TextField("0", text: binding(for: category))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .accessibilityLabel("\(category.rawValue) monthly target in euros")
                                .accessibilityIdentifier("budget-target-\(category.accessibilityID)")
                        }
                    }
                } footer: {
                    Text("Targets repeat every month and are compared with one-time and active recurring expenses.")
                }
            }
            .navigationTitle("Monthly Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("budget-targets-save")
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func binding(for category: ExpenseCategory) -> Binding<String> {
        Binding(
            get: { amounts[category] ?? "0" },
            set: { amounts[category] = $0 }
        )
    }

    private func save() {
        let targets = ExpenseCategory.allCases.map { category in
            MonthlyBudgetTarget(category: category, amount: decimal(amounts[category]) ?? 0)
        }
        budgetStore.updateTargets(targets)
        dismiss()
    }

    private func decimal(_ text: String?) -> Decimal? {
        Decimal(string: (text ?? "").replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX"))
    }
}

struct FundingEditorView: View {
    @Environment(BudgetStore.self) private var budgetStore
    @Environment(\.dismiss) private var dismiss
    @State private var relocationCash: String
    @State private var deposits: String
    @State private var emergencyReserve: String

    init(funding: RelocationFunding) {
        _relocationCash = State(initialValue: NSDecimalNumber(decimal: funding.relocationCash).stringValue)
        _deposits = State(initialValue: NSDecimalNumber(decimal: funding.deposits).stringValue)
        _emergencyReserve = State(initialValue: NSDecimalNumber(decimal: funding.emergencyReserve).stringValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                currencyField("Relocation cash", text: $relocationCash, id: "funding-cash")
                currencyField("Deposits", text: $deposits, id: "funding-deposits")
                currencyField("Emergency reserve", text: $emergencyReserve, id: "funding-emergency")
            }
            .navigationTitle("Relocation Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("funding-save")
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func currencyField(_ title: String, text: Binding<String>, id: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
                .accessibilityLabel("\(title) in euros")
                .accessibilityIdentifier(id)
        }
    }

    private func save() {
        budgetStore.updateFunding(
            RelocationFunding(
                relocationCash: decimal(relocationCash),
                deposits: decimal(deposits),
                emergencyReserve: decimal(emergencyReserve)
            )
        )
        dismiss()
    }

    private func decimal(_ text: String) -> Decimal {
        max(Decimal(string: text.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) ?? 0, 0)
    }
}
