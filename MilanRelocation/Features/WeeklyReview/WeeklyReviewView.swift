import SwiftUI

private struct ReviewEditorContext: Identifiable { let id = UUID(); let entry: WeeklyReviewEntry? }

struct WeeklyReviewView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(WeeklyReviewStore.self) private var reviewStore
    @State private var editor: ReviewEditorContext?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Friday ritual", title: "Weekly Review", detail: "Save a shared checkpoint for progress, blockers, and next week.")
                MetricGrid(columns: 2) {
                    MetricBlock(label: "Completed", value: "\(taskStore.tasks.filter { $0.status == .complete }.count)", detail: "tasks in plan", emphasized: true)
                    MetricBlock(label: "Reviews", value: "\(reviewStore.entries.count)", detail: "saved check-ins")
                }
                if let error = reviewStore.error { ContentStateView(kind: .error, title: "Review save issue", detail: error) }
                SectionLabel(title: "Saved reviews")
                if reviewStore.entries.isEmpty {
                    ContentStateView(kind: .empty, title: "No weekly review yet", detail: "Capture this week’s progress, blockers, and priorities.")
                } else {
                    ForEach(reviewStore.entries) { entry in
                        Button { editor = ReviewEditorContext(entry: entry) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Week of \(entry.weekOf.formatted(date: .abbreviated, time: .omitted))").font(.headline)
                                if !entry.progress.isEmpty { Label(entry.progress, systemImage: "checkmark.circle") }
                                if !entry.blockers.isEmpty { Label(entry.blockers, systemImage: "exclamationmark.triangle") }
                                if !entry.priorities.isEmpty { Label(entry.priorities, systemImage: "arrow.right.circle") }
                            }.font(.subheadline).foregroundStyle(MRColor.ink).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("review-row-\(entry.id.uuidString)")
                        Divider().overlay(MRColor.divider)
                    }
                }
            }.relocationPage()
        }
        .navigationTitle("Weekly Review").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button { editor = ReviewEditorContext(entry: nil) } label: { Label("New weekly review", systemImage: "plus") }.accessibilityIdentifier("review-add") }
        .sheet(item: $editor) { WeeklyReviewEditorView(entry: $0.entry).environment(reviewStore) }
    }
}
