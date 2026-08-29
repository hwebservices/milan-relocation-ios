import SwiftUI

struct DocumentFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var owner: TaskOwner?
    @Binding var category: DocumentCategory?
    @Binding var status: DocumentStatus?
    @Binding var includeArchived: Bool

    var body: some View {
        NavigationStack {
            Form {
                Picker("Owner", selection: $owner) {
                    Text("All owners").tag(nil as TaskOwner?)
                    ForEach(TaskOwner.allCases) { Text($0.rawValue).tag($0 as TaskOwner?) }
                }
                .accessibilityIdentifier("document-filter-owner")
                Picker("Category", selection: $category) {
                    Text("All categories").tag(nil as DocumentCategory?)
                    ForEach(DocumentCategory.allCases) { Text($0.rawValue).tag($0 as DocumentCategory?) }
                }
                .accessibilityIdentifier("document-filter-category")
                Picker("Status", selection: $status) {
                    Text("All statuses").tag(nil as DocumentStatus?)
                    ForEach(DocumentStatus.allCases) { Text($0.rawValue).tag($0 as DocumentStatus?) }
                }
                .accessibilityIdentifier("document-filter-status")
                Toggle("Show archived documents", isOn: $includeArchived)
                    .accessibilityIdentifier("document-filter-archived")
                Button("Clear filters") {
                    owner = nil
                    category = nil
                    status = nil
                    includeArchived = false
                }
                .accessibilityIdentifier("document-clear-filters")
            }
            .navigationTitle("Document Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("document-apply-filters")
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
