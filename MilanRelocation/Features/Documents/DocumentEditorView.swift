import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct DocumentEditorView: View {
    @Environment(DocumentStore.self) private var documentStore
    @Environment(\.dismiss) private var dismiss

    private let originalDocument: RelocationDocument?

    @State private var name: String
    @State private var owner: TaskOwner
    @State private var category: DocumentCategory
    @State private var status: DocumentStatus
    @State private var includesIssueDate: Bool
    @State private var issueDate: Date
    @State private var includesExpirationDate: Bool
    @State private var expirationDate: Date
    @State private var requiredFor: String
    @State private var notes: String
    @State private var sourceInformation: String
    @State private var attachments: [DocumentAttachmentMetadata]
    @State private var showsArchiveConfirmation = false
    @State private var showsFileImporter = false
    @State private var previewURL: URL?
    @State private var importError: String?
    @State private var newlyImportedPaths: Set<String> = []
    @State private var pathsToRemoveOnSave: Set<String> = []
    private let attachmentService = LocalAttachmentService()

    init(document: RelocationDocument?) {
        originalDocument = document
        _name = State(initialValue: document?.name ?? "")
        _owner = State(initialValue: document?.owner ?? .both)
        _category = State(initialValue: document?.category ?? .identity)
        _status = State(initialValue: document?.status ?? .notStarted)
        _includesIssueDate = State(initialValue: document?.issueDate != nil)
        _issueDate = State(initialValue: document?.issueDate ?? .now)
        _includesExpirationDate = State(initialValue: document?.expirationDate != nil)
        _expirationDate = State(initialValue: document?.expirationDate ?? Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now)
        _requiredFor = State(initialValue: document?.requiredFor ?? "")
        _notes = State(initialValue: document?.notes ?? "")
        _sourceInformation = State(initialValue: document?.sourceInformation ?? "")
        _attachments = State(initialValue: document?.attachments ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    TextField("Document name", text: $name)
                        .accessibilityIdentifier("document-name")
                    Picker("Owner", selection: $owner) {
                        ForEach(TaskOwner.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("document-owner")
                    Picker("Category", selection: $category) {
                        ForEach(DocumentCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("document-category")
                    Picker("Status", selection: $status) {
                        ForEach(DocumentStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .accessibilityIdentifier("document-status")
                }

                Section("Dates") {
                    Toggle("Record issue date", isOn: $includesIssueDate)
                        .accessibilityIdentifier("document-issue-toggle")
                    if includesIssueDate {
                        DatePicker("Issued", selection: $issueDate, displayedComponents: .date)
                            .accessibilityIdentifier("document-issue-date")
                    }
                    Toggle("Record expiration date", isOn: $includesExpirationDate)
                        .accessibilityIdentifier("document-expiration-toggle")
                    if includesExpirationDate {
                        DatePicker("Expires", selection: $expirationDate, in: minimumExpirationDate..., displayedComponents: .date)
                            .accessibilityIdentifier("document-expiration-date")
                    }
                }

                Section("Application or process") {
                    TextField("Required for", text: $requiredFor, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityIdentifier("document-required-for")
                    TextField("Source information", text: $sourceInformation, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityIdentifier("document-source")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 90)
                        .accessibilityIdentifier("document-notes")
                }

                Section {
                    Button { showsFileImporter = true } label: { Label("Import files", systemImage: "paperclip") }
                        .accessibilityIdentifier("document-add-attachment")
                    ForEach(attachments) { attachment in
                        Button { previewURL = attachmentService.url(for: attachment.localRelativePath) } label: { Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.fileName)
                                Text(attachment.byteCount.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) } ?? "Local file")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "paperclip")
                        } }.buttonStyle(.plain).disabled(attachmentService.url(for: attachment.localRelativePath) == nil)
                        .accessibilityElement(children: .combine)
                    }
                    .onDelete(perform: removeAttachments)
                } header: {
                    Text("Attachments")
                } footer: {
                    Text("Files are copied into this app’s private local storage and are never uploaded.")
                }

                if let originalDocument {
                    Section {
                        if originalDocument.isArchived {
                            Button("Restore Document") { restoreDocument() }
                                .frame(maxWidth: .infinity)
                                .accessibilityIdentifier("document-restore")
                        } else {
                            Button("Archive Document", role: .destructive) {
                                showsArchiveConfirmation = true
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("document-archive")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MRColor.background)
            .navigationTitle(originalDocument == nil ? "New Document" : "Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                        .accessibilityIdentifier("document-cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                        .accessibilityIdentifier("document-save")
                }
            }
            .alert("Archive this document?", isPresented: $showsArchiveConfirmation) {
                Button("Archive", role: .destructive) { archiveDocument() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("“\(name)” will be hidden from the active checklist and its expiration reminder will be cancelled.")
            }
            .onChange(of: issueDate) { _, newIssueDate in
                guard includesIssueDate, includesExpirationDate, expirationDate < newIssueDate else { return }
                expirationDate = newIssueDate
            }
            .onChange(of: includesIssueDate) { _, includesDate in
                guard includesDate, includesExpirationDate, expirationDate < issueDate else { return }
                expirationDate = issueDate
            }
            .fileImporter(isPresented: $showsFileImporter, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in importFiles(result) }
            .quickLookPreview($previewURL)
            .alert("File import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) { Button("OK") { importError = nil } } message: { Text(importError ?? "The selected file could not be copied.") }
        }
        .preferredColorScheme(.light)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var minimumExpirationDate: Date { includesIssueDate ? Calendar.current.startOfDay(for: issueDate) : .distantPast }

    private func save() {
        let cleanRequirement = requiredFor.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSource = sourceInformation.trimmingCharacters(in: .whitespacesAndNewlines)
        let document = RelocationDocument(
            id: originalDocument?.id ?? UUID(), name: trimmedName, owner: owner, category: category, status: status,
            issueDate: includesIssueDate ? issueDate : nil,
            expirationDate: includesExpirationDate ? expirationDate : nil,
            requiredFor: cleanRequirement,
            notes: cleanNotes.isEmpty ? nil : cleanNotes,
            sourceInformation: cleanSource.isEmpty ? nil : cleanSource,
            attachments: attachments,
            isArchived: originalDocument?.isArchived ?? false,
            createdAt: originalDocument?.createdAt ?? .now,
            updatedAt: .now
        )
        if originalDocument == nil { documentStore.create(document) }
        else { documentStore.update(document) }
        pathsToRemoveOnSave.forEach { attachmentService.remove(relativePath: $0) }
        dismiss()
    }

    private func archiveDocument() {
        guard let originalDocument else { return }
        documentStore.setArchived(true, id: originalDocument.id)
        dismiss()
    }

    private func restoreDocument() {
        guard let originalDocument else { return }
        documentStore.setArchived(false, id: originalDocument.id)
        dismiss()
    }

    private func cancel() { newlyImportedPaths.forEach { attachmentService.remove(relativePath: $0) }; dismiss() }
    private func removeAttachments(at offsets: IndexSet) {
        offsets.map { attachments[$0] }.forEach { stageRemoval(of: $0.localRelativePath) }
        attachments.remove(atOffsets: offsets)
    }
    private func stageRemoval(of relativePath: String?) {
        guard let relativePath else { return }
        if newlyImportedPaths.remove(relativePath) != nil {
            attachmentService.remove(relativePath: relativePath)
        } else {
            pathsToRemoveOnSave.insert(relativePath)
        }
    }
    private func importFiles(_ result: Result<[URL], Error>) {
        do {
            for source in try result.get() {
                let imported = try attachmentService.importFile(from: source)
                let type = (try? source.resourceValues(forKeys: [.contentTypeKey]).contentType?.preferredMIMEType) ?? "application/octet-stream"
                attachments.append(DocumentAttachmentMetadata(fileName: source.lastPathComponent, contentType: type, byteCount: imported.byteCount, localRelativePath: imported.relativePath))
                newlyImportedPaths.insert(imported.relativePath)
            }
        } catch { importError = error.localizedDescription }
    }
}
