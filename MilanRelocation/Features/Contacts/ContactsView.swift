import SwiftUI

struct ContactsView: View {
    @Environment(MockRelocationStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Milan network", title: "Contacts", detail: "Advisors and local partners helping with the move.")
                ForEach(store.contacts) { contact in
                    HStack(spacing: MRSpacing.md) {
                        Text(contact.name.split(separator: " ").compactMap { $0.first }.map(String.init).joined())
                            .font(.caption.weight(.bold)).foregroundStyle(.white).frame(width: 42, height: 42).background(MRColor.accent, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(contact.name).font(.body.weight(.semibold))
                            Text("\(contact.role) · \(contact.organization)").font(.caption).foregroundStyle(MRColor.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "envelope").foregroundStyle(MRColor.accent).accessibilityLabel("Email \(contact.name)")
                    }.padding(.vertical, 10)
                    Divider().overlay(MRColor.divider)
                }
            }.relocationPage()
        }.navigationTitle("Contacts").navigationBarTitleDisplayMode(.inline)
    }
}
