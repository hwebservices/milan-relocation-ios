import SwiftUI

struct TaskEditorView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(\.dismiss) private var dismiss

    private let originalTask: RelocationTask?

    @State private var title: String
    @State private var category: String
    @State private var owner: TaskOwner
    @State private var status: TaskStatus
    @State private var priority: TaskPriority
    @State private var includesStartDate: Bool
    @State private var startDate: Date
    @State private var dueDate: Date
    @State private var notes: String
    @State private var showsDeleteConfirmation = false

    init(task: RelocationTask?) {
        originalTask = task
        _title = State(initialValue: task?.title ?? "")
        _category = State(initialValue: task?.category ?? "General")
        _owner = State(initialValue: task?.owner ?? .both)
        _status = State(initialValue: task?.status ?? .notStarted)
        _priority = State(initialValue: task?.priority ?? .medium)
        _includesStartDate = State(initialValue: task?.startDate != nil)
        _startDate = State(initialValue: task?.startDate ?? .now)
        _dueDate = State(initialValue: task?.dueDate ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
        _notes = State(initialValue: task?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                        .accessibilityIdentifier("task-title")
                    TextField("Category", text: $category)
                        .accessibilityIdentifier("task-category")
                }

                Section("Assignment") {
                    Picker("Owner", selection: $owner) {
                        ForEach(TaskOwner.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("task-owner")

                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("task-status")

                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("task-priority")
                }

                Section("Schedule") {
                    Toggle("Set a start date", isOn: $includesStartDate)
                        .accessibilityIdentifier("task-start-toggle")
                    if includesStartDate {
                        DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                            .accessibilityIdentifier("task-start-date")
                    }
                    DatePicker("Due", selection: $dueDate, in: minimumDueDate..., displayedComponents: .date)
                        .accessibilityIdentifier("task-due-date")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 110)
                        .accessibilityIdentifier("task-notes")
                }

                if originalTask != nil {
                    Section {
                        Button("Delete Task", role: .destructive) {
                            showsDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("task-delete")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MRColor.background)
            .navigationTitle(originalTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("task-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trimmedTitle.isEmpty)
                        .accessibilityIdentifier("task-save")
                }
            }
            .alert("Delete this task?", isPresented: $showsDeleteConfirmation) {
                Button("Delete", role: .destructive) { deleteTask() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes “\(title)” from the shared plan. This action cannot be undone.")
            }
            .onChange(of: startDate) { _, newStartDate in
                guard includesStartDate, dueDate < newStartDate else { return }
                dueDate = newStartDate
            }
            .onChange(of: includesStartDate) { _, includesDate in
                guard includesDate, dueDate < startDate else { return }
                dueDate = startDate
            }
        }
        .preferredColorScheme(.light)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var minimumDueDate: Date { includesStartDate ? Calendar.current.startOfDay(for: startDate) : .distantPast }

    private func save() {
        let cleanedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = RelocationTask(
            id: originalTask?.id ?? UUID(),
            title: trimmedTitle,
            category: cleanedCategory.isEmpty ? "General" : cleanedCategory,
            owner: owner,
            status: status,
            priority: priority,
            startDate: includesStartDate ? startDate : nil,
            dueDate: dueDate,
            notes: cleanedNotes.isEmpty ? nil : cleanedNotes
        )
        if originalTask == nil { taskStore.create(task) }
        else { taskStore.update(task) }
        dismiss()
    }

    private func deleteTask() {
        guard let originalTask else { return }
        taskStore.delete(id: originalTask.id)
        dismiss()
    }
}
