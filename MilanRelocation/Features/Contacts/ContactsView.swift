import SwiftUI

private struct ContactEditorContext: Identifiable { let id = UUID(); let contact: ContactItem? }

struct ContactsView: View {
    @Environment(ContactStore.self) private var store
    @State private var editor: ContactEditorContext?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Milan network", title: "Contacts", detail: "Keep advisors and local partners current and reachable.")
                if let error = store.error { ContentStateView(kind: .error, title: "Contact save issue", detail: error) }
                if store.contacts.isEmpty {
                    ContentStateView(kind: .empty, title: "No contacts yet", detail: "Add the first person helping with the move.")
                } else {
                    ForEach(store.contacts) { contact in
                        HStack(spacing: MRSpacing.md) {
                            Button { editor = ContactEditorContext(contact: contact) } label: {
                                HStack(spacing: MRSpacing.md) {
                                Text(contact.name.split(separator: " ").compactMap(\.first).map(String.init).joined())
                                    .font(.caption.weight(.bold)).foregroundStyle(.white).frame(width: 42, height: 42).background(MRColor.accent, in: Circle())
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(contact.name).font(.body.weight(.semibold))
                                    if !contactDetail(contact).isEmpty {
                                        Text(contactDetail(contact)).font(.caption).foregroundStyle(MRColor.secondaryText)
                                    }
                                }
                                Spacer()
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel([contact.name, contactDetail(contact)].filter { !$0.isEmpty }.joined(separator: ", "))
                            .accessibilityIdentifier("contact-row-\(contact.id.uuidString)")
                            if !contact.email.isEmpty, let emailURL = URL(string: "mailto:\(contact.email)") {
                                Link(destination: emailURL) { Image(systemName: "envelope") }
                                    .accessibilityLabel("Email \(contact.name)")
                            }
                        }
                        Divider().overlay(MRColor.divider)
                    }
                }
            }.relocationPage()
        }.navigationTitle("Contacts").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button { editor = ContactEditorContext(contact: nil) } label: { Label("New contact", systemImage: "plus") }.accessibilityIdentifier("contacts-add-contact") }
        .sheet(item: $editor) { ContactEditorView(contact: $0.contact).environment(store) }
    }

    private func contactDetail(_ contact: ContactItem) -> String {
        [contact.role, contact.organization].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
