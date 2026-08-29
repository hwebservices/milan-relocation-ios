import SwiftUI

struct ContactEditorView: View {
    @Environment(ContactStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private let original: ContactItem?
    @State private var name: String
    @State private var role: String
    @State private var organization: String
    @State private var email: String
    @State private var phone: String
    @State private var notes: String
    @State private var confirmsDelete = false

    init(contact: ContactItem?) {
        original = contact
        _name = State(initialValue: contact?.name ?? "")
        _role = State(initialValue: contact?.role ?? "")
        _organization = State(initialValue: contact?.organization ?? "")
        _email = State(initialValue: contact?.email ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
        _notes = State(initialValue: contact?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Name", text: $name).accessibilityIdentifier("contact-name")
                    TextField("Role", text: $role).accessibilityIdentifier("contact-role")
                    TextField("Organization", text: $organization).accessibilityIdentifier("contact-organization")
                }
                Section("Reach them") {
                    TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never).accessibilityIdentifier("contact-email")
                    TextField("Phone", text: $phone).keyboardType(.phonePad).accessibilityIdentifier("contact-phone")
                }
                Section("Notes") { TextEditor(text: $notes).frame(minHeight: 100).accessibilityIdentifier("contact-notes") }
                if original != nil { Section { Button("Delete Contact", role: .destructive) { confirmsDelete = true }.frame(maxWidth: .infinity).accessibilityIdentifier("contact-delete") } }
            }
            .navigationTitle(original == nil ? "New Contact" : "Edit Contact").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(trimmedName.isEmpty).accessibilityIdentifier("contact-save") }
            }
            .alert("Delete this contact?", isPresented: $confirmsDelete) {
                Button("Delete", role: .destructive) { if let original { store.delete(id: original.id) }; dismiss() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func cleaned(_ value: String) -> String? { let result = value.trimmingCharacters(in: .whitespacesAndNewlines); return result.isEmpty ? nil : result }
    private func save() {
        let contact = ContactItem(id: original?.id ?? UUID(), name: trimmedName, role: cleaned(role) ?? "", organization: cleaned(organization) ?? "", email: cleaned(email) ?? "", phone: cleaned(phone), notes: cleaned(notes))
        if original == nil { store.create(contact) } else { store.update(contact) }
        dismiss()
    }
}
