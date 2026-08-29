import SwiftUI

struct TasksView: View {
    @Environment(MockRelocationStore.self) private var store
    @State private var statusFilter: TaskStatus?

    private var filteredTasks: [RelocationTask] {
        guard let statusFilter else { return store.tasks }
        return store.tasks.filter { $0.status == statusFilter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Shared workload", title: "Tasks", detail: "Ownership, deadlines, and dependencies in one place.")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterButton("All", status: nil)
                        ForEach(TaskStatus.allCases) { status in filterButton(status.title, status: status) }
                    }
                }
                if filteredTasks.isEmpty {
                    ContentStateView(kind: .empty, title: "No tasks here", detail: "This filter has no matching relocation tasks.")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task)
                            Divider().overlay(MRColor.divider)
                        }
                    }
                }
            }
            .relocationPage()
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func filterButton(_ title: String, status: TaskStatus?) -> some View {
        let selected = statusFilter == status
        return Button(title) { withAnimation(.easeOut(duration: 0.18)) { statusFilter = status } }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .foregroundStyle(selected ? Color.white : MRColor.ink)
            .background(selected ? MRColor.accent : MRColor.surface, in: Capsule())
            .accessibilityValue(selected ? "Selected" : "Not selected")
    }
}
