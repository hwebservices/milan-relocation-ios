import SwiftUI

private struct EducationTaskContext: Identifiable { let id = UUID(); let task: RelocationTask? }

struct EducationWorkView: View {
    @Environment(TaskStore.self) private var store
    @State private var editor: EducationTaskContext?
    private var tasks: [RelocationTask] { store.tasks.filter { $0.category == "Education & Work" } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Next chapter", title: "Education & Work", detail: "Coordinate professional transitions and language learning.")
                SectionLabel(title: "In motion")
                if tasks.isEmpty {
                    ContentStateView(kind: .empty, title: "No education or work actions", detail: "Add the first language, credential, or employment task.")
                } else {
                    ForEach(tasks) { task in
                        Button { editor = EducationTaskContext(task: task) } label: { TaskRow(task: task).contentShape(Rectangle()) }
                            .buttonStyle(.plain).accessibilityIdentifier("education-task-\(task.id.uuidString)")
                        Divider().overlay(MRColor.divider)
                    }
                }
            }.relocationPage()
        }.navigationTitle("Education & Work").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button { editor = EducationTaskContext(task: nil) } label: { Label("New education or work task", systemImage: "plus") }.accessibilityIdentifier("education-add-task") }
        .sheet(item: $editor) { TaskEditorView(task: $0.task, defaultCategory: "Education & Work").environment(store) }
    }
}
