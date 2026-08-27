import SwiftUI

struct DocumentsView: View {
    @Environment(MockRelocationStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Private checklist", title: "Documents", detail: "Readiness tracking only—no files are uploaded in this version.")
                ForEach(store.documents) { document in
                    HStack(spacing: MRSpacing.md) {
                        Image(systemName: document.isReady ? "checkmark.seal.fill" : "doc.badge.clock").font(.title2).foregroundStyle(document.isReady ? MRColor.success : MRColor.amber)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(document.name).font(.body.weight(.semibold))
                            Text(document.category).font(.caption).foregroundStyle(MRColor.secondaryText)
                        }
                        Spacer()
                        OwnerLabel(owner: document.owner)
                    }.padding(.vertical, 10)
                    Divider().overlay(MRColor.divider)
                }
            }.relocationPage()
        }.navigationTitle("Documents")
    }
}

