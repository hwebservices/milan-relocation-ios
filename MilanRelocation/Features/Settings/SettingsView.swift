import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("showCompletedTasks") private var showCompleted = true
    @State private var showsNotificationSettings = false
    @Environment(NotificationService.self) private var notificationService
    @Environment(TaskStore.self) private var taskStore
    @Environment(BudgetStore.self) private var budgetStore
    @Environment(HousingStore.self) private var housingStore
    @Environment(DocumentStore.self) private var documentStore
    @Environment(ContactStore.self) private var contactStore
    @Environment(WeeklyReviewStore.self) private var weeklyReviewStore
    @State private var exportDocument: RelocationBackupDocument?
    @State private var showsExporter = false
    @State private var showsImporter = false
    @State private var pendingBackup: RelocationBackup?
    @State private var transferError: String?
    @State private var restoreSucceeded = false

    var body: some View {
        Form {
            Section("Workspace") {
                LabeledContent("Members", value: "Henry & Jeff")
                LabeledContent("Currency", value: "EUR (€)")
                LabeledContent("Data", value: "Local on-device")
            }
            Section("Preferences") {
                Button {
                    showsNotificationSettings = true
                } label: {
                    HStack {
                        Label("Notifications", systemImage: "bell.badge")
                        Spacer()
                        Text(notificationService.permissionStatus.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("settings-notifications")
                Toggle("Show completed tasks", isOn: $showCompleted)
                    .accessibilityIdentifier("settings-show-completed")
            }
            Section("Privacy") {
                Label("No account or cloud connection", systemImage: "lock.shield")
                Text("This app does not upload documents, sync personal data, or use push notifications. Optional reminders are scheduled locally on this device.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Backup") {
                Button { prepareExport() } label: { Label("Export local backup", systemImage: "square.and.arrow.up") }
                    .accessibilityIdentifier("settings-export-backup")
                Button { showsImporter = true } label: { Label("Restore from backup", systemImage: "square.and.arrow.down") }
                    .accessibilityIdentifier("settings-import-backup")
            }
        }
        .scrollContentBackground(.hidden)
        .background(MRColor.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsNotificationSettings) {
            NotificationSettingsView()
        }
        .task { await notificationService.refreshPermissionStatus() }
        .fileExporter(isPresented: $showsExporter, document: exportDocument, contentType: .json, defaultFilename: "Milan-Relocation-Backup") { result in if case .failure(let error) = result { transferError = error.localizedDescription } }
        .fileImporter(isPresented: $showsImporter, allowedContentTypes: [.json]) { result in loadBackup(result) }
        .alert("Restore this backup?", isPresented: Binding(get: { pendingBackup != nil }, set: { if !$0 { pendingBackup = nil } })) {
            Button("Restore", role: .destructive) { restoreBackup() }
            Button("Cancel", role: .cancel) { pendingBackup = nil }
        } message: { Text("Current local data will be replaced with the selected backup.") }
        .alert("Backup operation failed", isPresented: Binding(get: { transferError != nil }, set: { if !$0 { transferError = nil } })) { Button("OK") { transferError = nil } } message: { Text(transferError ?? "Please try again.") }
        .alert("Backup restored", isPresented: $restoreSucceeded) { Button("OK") {} } message: { Text("The local workspace and its attachments were restored successfully.") }
    }

    private func prepareExport() {
        do {
            let attachmentService = LocalAttachmentService()
            let paths = Set(attachmentPaths(expenses: budgetStore.expenses, documents: documentStore.documents))
            var files: [String: Data] = [:]
            for path in paths {
                guard let data = attachmentService.data(for: path) else { throw BackupTransferError.missingAttachment(path) }
                files[path] = data
            }
            exportDocument = RelocationBackupDocument(backup: RelocationBackup(formatVersion: 1, createdAt: .now, tasks: taskStore.tasks, budget: budgetStore.data, housing: housingStore.data, documents: documentStore.documents, contacts: contactStore.contacts, weeklyReviews: weeklyReviewStore.entries, showCompletedTasks: showCompleted, attachmentFiles: files))
            showsExporter = true
        } catch { transferError = error.localizedDescription }
    }

    private func loadBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get(); let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let backup = try JSONDecoder().decode(RelocationBackup.self, from: Data(contentsOf: url))
            guard backup.formatVersion == 1 else { throw CocoaError(.fileReadUnsupportedScheme) }
            pendingBackup = backup
        } catch { transferError = error.localizedDescription }
    }

    private func restoreBackup() {
        guard let backup = pendingBackup else { return }
        do {
            try backup.validateAttachmentCompleteness()
            let attachmentService = LocalAttachmentService()
            var restoredPaths: [String] = []
            do {
                for (path, data) in backup.attachmentFiles {
                    try attachmentService.restore(data, relativePath: path)
                    restoredPaths.append(path)
                }
            } catch {
                restoredPaths.forEach { attachmentService.remove(relativePath: $0) }
                throw error
            }
            taskStore.replaceAll(with: backup.tasks); budgetStore.replaceAll(with: backup.budget); housingStore.replaceAll(with: backup.housing)
            documentStore.replaceAll(with: backup.documents); contactStore.replaceAll(with: backup.contacts); weeklyReviewStore.replaceAll(with: backup.weeklyReviews)
            showCompleted = backup.showCompletedTasks
            pendingBackup = nil
            restoreSucceeded = true
        } catch {
            pendingBackup = nil
            transferError = error.localizedDescription
        }
    }

    private func attachmentPaths(expenses: [Expense], documents: [RelocationDocument]) -> [String] {
        let receiptPaths = expenses.flatMap(\.receipts).compactMap(\.localRelativePath)
        let documentPaths = documents.flatMap(\.attachments).compactMap(\.localRelativePath)
        return receiptPaths + documentPaths
    }
}

private enum BackupTransferError: LocalizedError {
    case missingAttachment(String)

    var errorDescription: String? {
        switch self {
        case .missingAttachment(let path): "The attachment \(path) is missing, so a complete backup could not be created."
        }
    }
}
