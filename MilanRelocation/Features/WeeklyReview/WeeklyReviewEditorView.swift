import SwiftUI

struct WeeklyReviewEditorView: View {
    @Environment(WeeklyReviewStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private let original: WeeklyReviewEntry?
    @State private var weekOf: Date
    @State private var progress: String
    @State private var blockers: String
    @State private var priorities: String
    @State private var confirmsDelete = false

    init(entry: WeeklyReviewEntry?) {
        original = entry
        _weekOf = State(initialValue: entry?.weekOf ?? Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now)
        _progress = State(initialValue: entry?.progress ?? "")
        _blockers = State(initialValue: entry?.blockers ?? "")
        _priorities = State(initialValue: entry?.priorities ?? "")
    }
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Week of", selection: $weekOf, displayedComponents: .date).accessibilityIdentifier("review-week")
                prompt("What moved forward?", text: $progress, id: "review-progress")
                prompt("What is blocked?", text: $blockers, id: "review-blockers")
                prompt("What matters next week?", text: $priorities, id: "review-priorities")
                if original != nil { Section { Button("Delete Review", role: .destructive) { confirmsDelete = true }.frame(maxWidth: .infinity) } }
            }
            .navigationTitle(original == nil ? "New Review" : "Edit Review").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave).accessibilityIdentifier("review-save") }
            }
            .alert("Delete this weekly review?", isPresented: $confirmsDelete) { Button("Delete", role: .destructive) { if let original { store.delete(id: original.id) }; dismiss() }; Button("Cancel", role: .cancel) {} }
        }
    }
    private func prompt(_ title: String, text: Binding<String>, id: String) -> some View { Section(title) { TextEditor(text: text).frame(minHeight: 100).accessibilityIdentifier(id) } }
    private var canSave: Bool { [progress, blockers, priorities].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
    private func save() { store.save(WeeklyReviewEntry(id: original?.id ?? UUID(), weekOf: Calendar.current.startOfDay(for: weekOf), progress: progress.trimmingCharacters(in: .whitespacesAndNewlines), blockers: blockers.trimmingCharacters(in: .whitespacesAndNewlines), priorities: priorities.trimmingCharacters(in: .whitespacesAndNewlines))); dismiss() }
}
