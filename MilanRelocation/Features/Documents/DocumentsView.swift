import SwiftUI

private struct DocumentEditorContext: Identifiable {
    let id = UUID()
    let document: RelocationDocument?
}

struct DocumentsView: View {
    @Environment(DocumentStore.self) private var documentStore

    @State private var ownerFilter: TaskOwner?
    @State private var categoryFilter: DocumentCategory?
    @State private var statusFilter: DocumentStatus?
    @State private var includeArchived = false
    @State private var showsFilters = false
    @State private var editorContext: DocumentEditorContext?

    private var filteredDocuments: [RelocationDocument] {
        documentStore.filtered(
            owner: ownerFilter, category: categoryFilter, status: statusFilter, includeArchived: includeArchived
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(
                    eyebrow: "Private checklist",
                    title: "Document tracker",
                    detail: "Keep every Milan application record current, complete, and ready before it becomes urgent."
                )
                summary
                documentList
            }
            .relocationPage()
        }
        .background(MRColor.background)
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showsFilters = true } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter documents")
                .accessibilityIdentifier("document-filter-button")
                Button { editorContext = DocumentEditorContext(document: nil) } label: {
                    Label("New document", systemImage: "plus")
                }
                .accessibilityIdentifier("documents-add-document")
            }
        }
        .sheet(item: $editorContext) { context in
            DocumentEditorView(document: context.document)
                .environment(documentStore)
        }
        .sheet(isPresented: $showsFilters) {
            DocumentFiltersView(
                owner: $ownerFilter, category: $categoryFilter, status: $statusFilter,
                includeArchived: $includeArchived
            )
        }
    }

    private var summary: some View {
        MetricGrid(columns: 3) {
            MetricBlock(label: "Missing", value: "\(documentStore.missing().count)", detail: "need action")
            MetricBlock(label: "Expiring soon", value: "\(documentStore.expiringSoon().count)", detail: "within 60 days", emphasized: true)
            MetricBlock(label: "Expired", value: "\(documentStore.expired().count)", detail: "replace now")
        }
        .accessibilityIdentifier("document-summary")
    }

    @ViewBuilder private var documentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(title: "Document checklist", action: filterSummary)
                .padding(.bottom, MRSpacing.sm)
            if documentStore.isLoading {
                ContentStateView(kind: .loading, title: "Loading documents", detail: "Opening the private local checklist.")
            } else if let error = documentStore.error {
                ContentStateView(kind: .error, title: "Documents unavailable", detail: error)
                    .accessibilityIdentifier("document-error-state")
            } else if documentStore.documents.filter({ !$0.isArchived }).isEmpty && !includeArchived {
                ContentStateView(kind: .empty, title: "No documents yet", detail: "Add the first document needed for your Milan move.")
                    .accessibilityIdentifier("document-empty-state")
            } else if filteredDocuments.isEmpty {
                ContentStateView(kind: .empty, title: "No matching documents", detail: "Clear or adjust the current document filters.")
                    .accessibilityIdentifier("document-no-results")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredDocuments) { document in
                        Button { editorContext = DocumentEditorContext(document: document) } label: {
                            DocumentRow(document: document)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("document-row-\(document.id.uuidString)")
                        Divider().overlay(MRColor.divider)
                    }
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        ownerFilter != nil || categoryFilter != nil || statusFilter != nil || includeArchived
    }

    private var filterSummary: String {
        hasActiveFilters ? "Filtered · \(filteredDocuments.count)" : "\(documentStore.documents.filter { !$0.isArchived }.count) active"
    }
}

private struct DocumentRow: View {
    let document: RelocationDocument

    private var status: DocumentStatus { document.effectiveStatus() }

    var body: some View {
        HStack(alignment: .top, spacing: MRSpacing.md) {
            Image(systemName: status.symbol)
                .font(.title3)
                .foregroundStyle(status.color)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Text(document.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MRColor.ink)
                    if document.isArchived {
                        Text("Archived")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(MRColor.secondaryText)
                    }
                }
                Text(document.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(MRColor.secondaryText)
                if !document.requiredFor.isEmpty {
                    Text("For \(document.requiredFor)")
                        .font(.caption)
                        .foregroundStyle(MRColor.secondaryText)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    DocumentStatusPill(status: status)
                    OwnerLabel(owner: document.owner)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                if let expirationDate = document.expirationDate {
                    Text(expirationDate.relocationShort)
                        .font(.caption.weight(.semibold))
                    Text(expirationLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(expirationColor)
                } else {
                    Text("No expiry")
                        .font(.caption)
                        .foregroundStyle(MRColor.secondaryText)
                }
                if !document.attachments.isEmpty {
                    Label("\(document.attachments.count)", systemImage: "paperclip")
                        .font(.caption2)
                        .foregroundStyle(MRColor.secondaryText)
                }
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var expirationLabel: String {
        if document.isExpired() { return "Expired" }
        if document.isExpiringSoon() { return "Expiring soon" }
        return "Expires"
    }

    private var expirationColor: Color {
        document.isExpired() ? MRColor.red : document.isExpiringSoon() ? MRColor.amber : MRColor.secondaryText
    }

    private var accessibilitySummary: String {
        var parts = [
            document.name, document.category.rawValue, status.rawValue,
            "owned by \(document.owner.rawValue)"
        ]
        if !document.requiredFor.isEmpty { parts.append("required for \(document.requiredFor)") }
        if let expirationDate = document.expirationDate {
            parts.append("expires \(expirationDate.formatted(date: .long, time: .omitted))")
            if document.isExpired() { parts.append("expired") }
            else if document.isExpiringSoon() { parts.append("expiring soon") }
        } else {
            parts.append("no expiration date")
        }
        if document.isArchived { parts.append("archived") }
        return parts.joined(separator: ", ")
    }
}

private struct DocumentStatusPill: View {
    let status: DocumentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(status.color)
            .background(status.color.opacity(0.11), in: Capsule())
    }
}

private extension DocumentStatus {
    var color: Color {
        switch self {
        case .notStarted: MRColor.secondaryText
        case .requested: MRColor.accent
        case .received: MRColor.success
        case .translationNeeded: MRColor.amber
        case .complete: MRColor.success
        case .expired: MRColor.red
        case .notApplicable: MRColor.secondaryText
        }
    }

    var symbol: String {
        switch self {
        case .notStarted: "doc"
        case .requested: "paperplane"
        case .received: "tray.and.arrow.down.fill"
        case .translationNeeded: "character.book.closed.fill"
        case .complete: "checkmark.seal.fill"
        case .expired: "exclamationmark.triangle.fill"
        case .notApplicable: "minus.circle"
        }
    }
}
