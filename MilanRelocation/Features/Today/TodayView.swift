import SwiftUI

struct TodayView: View {
    @Environment(TaskStore.self) private var store

    private var activeTasks: [RelocationTask] { store.tasks.filter { !$0.status.isTerminal }.prefix(4).map { $0 } }
    private var overdueCount: Int { store.tasks.filter { $0.isOverdue() }.count }
    private var moveDate: Date { Calendar.current.date(from: GanttTimelineLayout.moveDateComponents) ?? .now }
    private var daysToMove: Int { max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: moveDate)).day ?? 0) }
    private var currentFocus: RelocationTask? {
        store.tasks.filter { !$0.status.isTerminal }.sorted {
            if $0.priority.sortOrder != $1.priority.sortOrder { return $0.priority.sortOrder > $1.priority.sortOrder }
            return $0.dueDate < $1.dueDate
        }.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.xl) {
                PageHeader(eyebrow: Date.now.relocationLong, title: "Command Center", detail: "The next decisions for your move to Milan.")
                    .accessibilityIdentifier("today-command-center")

                MetricGrid(columns: 3) {
                    MetricBlock(label: "Active", value: "\(store.tasks.filter { !$0.status.isTerminal }.count)", detail: "open tasks", emphasized: true)
                    MetricBlock(label: "Overdue", value: "\(overdueCount)", detail: overdueCount == 1 ? "needs attention" : "need attention")
                    MetricBlock(label: "Move", value: "\(daysToMove)", detail: daysToMove == 1 ? "day remaining" : "days remaining")
                }
                .accessibilityIdentifier("today-metrics")

                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(title: "Up next", action: "Shared plan")
                    if activeTasks.isEmpty {
                        ContentStateView(kind: .empty, title: "Plan is clear", detail: "Create a task when the next relocation action is known.")
                    } else {
                        ForEach(activeTasks) { task in
                            TaskRow(task: task)
                            if task.id != activeTasks.last?.id { Divider().overlay(MRColor.divider) }
                        }
                    }
                }
                .accessibilityIdentifier("today-up-next")

                VStack(alignment: .leading, spacing: MRSpacing.md) {
                    SectionLabel(title: "Current focus")
                    if let currentFocus {
                        HStack(alignment: .top, spacing: MRSpacing.md) {
                            Image(systemName: "scope").font(.largeTitle).foregroundStyle(MRColor.accent)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(currentFocus.title).font(.headline)
                                Text(currentFocus.notes ?? "\(currentFocus.category) · due \(currentFocus.dueDate.relocationShort)").font(.subheadline).foregroundStyle(MRColor.secondaryText)
                            }
                        }
                        .padding(MRSpacing.lg)
                        .background(MRColor.accentSoft, in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        ContentStateView(kind: .empty, title: "No current focus", detail: "The highest-priority open task will appear here automatically.")
                    }
                }
                .accessibilityIdentifier("today-current-focus")
            }
            .relocationPage()
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
    }
}
