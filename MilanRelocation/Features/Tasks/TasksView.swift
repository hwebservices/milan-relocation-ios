import SwiftUI

private struct TaskEditorContext: Identifiable {
    let id = UUID()
    let task: RelocationTask?
}

struct TasksView: View {
    @Environment(TaskStore.self) private var taskStore
    @State private var statusFilter: TaskStatus?
    @State private var ownerFilter: TaskOwner?
    @State private var editorContext: TaskEditorContext?
    @AppStorage("showCompletedTasks") private var showCompleted = true

    private var filteredTasks: [RelocationTask] {
        taskStore.filtered(status: statusFilter, owner: ownerFilter)
            .filter { showCompleted || $0.status != .complete }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Shared workload", title: "Tasks", detail: "Create, assign, and move relocation work forward.")
                VStack(alignment: .leading, spacing: MRSpacing.sm) {
                    filterScroller {
                        filterButton("All statuses", selected: statusFilter == nil) { statusFilter = nil }
                        ForEach(TaskStatus.allCases) { status in
                            filterButton(status.title, selected: statusFilter == status) { statusFilter = status }
                        }
                    }
                    .accessibilityIdentifier("task-status-filters")

                    filterScroller {
                        filterButton("All owners", selected: ownerFilter == nil) { ownerFilter = nil }
                        ForEach(TaskOwner.allCases) { owner in
                            filterButton(owner.rawValue, selected: ownerFilter == owner) { ownerFilter = owner }
                        }
                    }
                    .accessibilityIdentifier("task-owner-filters")
                }
                if let message = taskStore.lastErrorMessage {
                    ContentStateView(kind: .error, title: "Local save issue", detail: message)
                }
                if filteredTasks.isEmpty {
                    ContentStateView(kind: .empty, title: "No tasks here", detail: "Adjust the filters or create a task for the shared plan.")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTasks) { task in
                            Button {
                                editorContext = TaskEditorContext(task: task)
                            } label: {
                                TaskRow(task: task)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("task-row-\(task.id.uuidString)")
                            Divider().overlay(MRColor.divider)
                        }
                    }
                }
            }
            .relocationPage()
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorContext = TaskEditorContext(task: nil)
                } label: {
                    Label("New task", systemImage: "plus")
                }
                .accessibilityIdentifier("tasks-add-task")
            }
        }
        .sheet(item: $editorContext) { context in
            TaskEditorView(task: context.task)
                .environment(taskStore)
        }
    }

    private func filterScroller<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) { content() }
        }
    }

    private func filterButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title) {
            withAnimation(.easeOut(duration: 0.18)) { action() }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(selected ? Color.white : MRColor.ink)
        .background(selected ? MRColor.accent : MRColor.surface, in: Capsule())
        .accessibilityValue(selected ? "Selected" : "Not selected")
    }
}
