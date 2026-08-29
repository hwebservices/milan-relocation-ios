import SwiftUI

struct TodayView: View {
    @Environment(TaskStore.self) private var store

    private var activeTasks: [RelocationTask] { store.tasks.filter { !$0.status.isTerminal }.prefix(4).map { $0 } }
    private var overdueCount: Int { store.tasks.filter { $0.isOverdue() }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.xl) {
                PageHeader(eyebrow: Date.now.relocationLong, title: "Command Center", detail: "The next decisions for your move to Milan.")
                    .accessibilityIdentifier("today-command-center")

                MetricGrid(columns: 3) {
                    MetricBlock(label: "Active", value: "\(store.tasks.filter { !$0.status.isTerminal }.count)", detail: "open tasks", emphasized: true)
                    MetricBlock(label: "Overdue", value: "\(overdueCount)", detail: overdueCount == 1 ? "needs attention" : "need attention")
                    MetricBlock(label: "Target", value: "110", detail: "days to settled")
                }
                .accessibilityIdentifier("today-metrics")

                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(title: "Up next", action: "Shared plan")
                    ForEach(activeTasks) { task in
                        TaskRow(task: task)
                        if task.id != activeTasks.last?.id { Divider().overlay(MRColor.divider) }
                    }
                }
                .accessibilityIdentifier("today-up-next")

                VStack(alignment: .leading, spacing: MRSpacing.md) {
                    SectionLabel(title: "Current focus")
                    HStack(alignment: .top, spacing: MRSpacing.md) {
                        Image(systemName: "building.2.crop.circle.fill").font(.largeTitle).foregroundStyle(MRColor.accent)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Secure a temporary Milan base").font(.headline)
                            Text("Agree on cancellation terms and shortlist two neighborhoods before committing.").font(.subheadline).foregroundStyle(MRColor.secondaryText)
                        }
                    }
                    .padding(MRSpacing.lg)
                    .background(MRColor.accentSoft, in: RoundedRectangle(cornerRadius: 18))
                }
                .accessibilityIdentifier("today-current-focus")
            }
            .relocationPage()
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
    }
}
