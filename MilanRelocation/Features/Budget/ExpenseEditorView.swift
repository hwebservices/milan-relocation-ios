import SwiftUI

struct ExpenseEditorView: View {
    @Environment(BudgetStore.self) private var budgetStore
    @Environment(\.dismiss) private var dismiss

    private let originalExpense: Expense?

    @State private var name: String
    @State private var amountText: String
    @State private var date: Date
    @State private var category: ExpenseCategory
    @State private var owner: TaskOwner
    @State private var recurrence: ExpenseRecurrence
    @State private var notes: String
    @State private var receipts: [ReceiptAttachment]
    @State private var showsDeleteConfirmation = false

    init(expense: Expense?) {
        originalExpense = expense
        _name = State(initialValue: expense?.name ?? "")
        _amountText = State(initialValue: expense.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
        _date = State(initialValue: expense?.date ?? .now)
        _category = State(initialValue: expense?.category ?? .other)
        _owner = State(initialValue: expense?.owner ?? .both)
        _recurrence = State(initialValue: expense?.recurrence ?? .oneTime)
        _notes = State(initialValue: expense?.notes ?? "")
        _receipts = State(initialValue: expense?.receipts ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("Description", text: $name)
                        .accessibilityIdentifier("expense-name")
                    TextField("Amount in euros", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("expense-amount")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("expense-date")
                }

                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("expense-category")

                    Picker("Owner", selection: $owner) {
                        ForEach(TaskOwner.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("expense-owner")

                    Picker("Frequency", selection: $recurrence) {
                        ForEach(ExpenseRecurrence.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("expense-recurrence")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 90)
                        .accessibilityIdentifier("expense-notes")
                }

                Section {
                    ForEach(receipts) { receipt in
                        HStack {
                            Label(receipt.displayName, systemImage: "doc.text")
                            Spacer()
                            Button(role: .destructive) {
                                receipts.removeAll { $0.id == receipt.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityLabel("Remove \(receipt.displayName)")
                        }
                    }
                    Button {
                        receipts.append(
                            ReceiptAttachment(displayName: "Receipt \(receipts.count + 1).pdf")
                        )
                    } label: {
                        Label("Add receipt placeholder", systemImage: "paperclip")
                    }
                    .accessibilityIdentifier("expense-add-receipt")
                } header: {
                    Text("Receipts")
                } footer: {
                    Text("Receipt placeholders remain on this device. File import will be added later.")
                }

                if originalExpense != nil {
                    Section {
                        Button("Delete Expense", role: .destructive) {
                            showsDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("expense-delete")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MRColor.background)
            .navigationTitle(originalExpense == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("expense-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .accessibilityIdentifier("expense-save")
                }
            }
            .alert("Delete this expense?", isPresented: $showsDeleteConfirmation) {
                Button("Delete", role: .destructive) { deleteExpense() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes “\(name)” from the local budget. This action cannot be undone.")
            }
        }
        .preferredColorScheme(.light)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var parsedAmount: Decimal? {
        Decimal(
            string: amountText.replacingOccurrences(of: ",", with: "."),
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
    private var canSave: Bool { !trimmedName.isEmpty && (parsedAmount ?? 0) > 0 }

    private func save() {
        guard let amount = parsedAmount else { return }
        let cleanedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let expense = Expense(
            id: originalExpense?.id ?? UUID(),
            name: trimmedName,
            amount: amount,
            date: date,
            category: category,
            owner: owner,
            recurrence: recurrence,
            notes: cleanedNotes.isEmpty ? nil : cleanedNotes,
            receipts: receipts
        )
        if originalExpense == nil { budgetStore.create(expense) }
        else { budgetStore.update(expense) }
        dismiss()
    }

    private func deleteExpense() {
        guard let originalExpense else { return }
        budgetStore.delete(id: originalExpense.id)
        dismiss()
    }
}
