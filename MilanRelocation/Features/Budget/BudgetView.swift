import SwiftUI

struct BudgetView: View {
    @Environment(MockRelocationStore.self) private var store

    private var planned: Decimal { store.budget.reduce(0) { $0 + $1.planned } }
    private var actual: Decimal { store.budget.reduce(0) { $0 + $1.actual } }
    private func euro(_ value: Decimal) -> String { value.formatted(.currency(code: "EUR").precision(.fractionLength(0))) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Relocation fund", title: "Budget", detail: "Planned and committed costs in euros.")
                MetricGrid(columns: 3) {
                    MetricBlock(label: "Plan", value: euro(planned), detail: "total envelope", emphasized: true)
                    MetricBlock(label: "Spent", value: euro(actual), detail: "recorded")
                    MetricBlock(label: "Remaining", value: euro(planned - actual), detail: "available")
                }
                SectionLabel(title: "By category")
                ForEach(store.budget) { item in
                    VStack(spacing: 8) {
                        HStack {
                            Text(item.category).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(euro(item.actual)) / \(euro(item.planned))").font(.caption).foregroundStyle(MRColor.secondaryText)
                        }
                        ProgressView(value: NSDecimalNumber(decimal: item.actual).doubleValue, total: NSDecimalNumber(decimal: item.planned).doubleValue).tint(MRColor.accent)
                    }
                    .padding(.vertical, 8)
                }
            }
            .relocationPage()
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
    }
}
