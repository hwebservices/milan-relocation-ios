import SwiftUI
import UniformTypeIdentifiers

struct RelocationBackup: Codable {
    let formatVersion: Int
    let createdAt: Date
    let tasks: [RelocationTask]
    let budget: BudgetData
    let housing: HousingData
    let documents: [RelocationDocument]
    let contacts: [ContactItem]
    let weeklyReviews: [WeeklyReviewEntry]
    let showCompletedTasks: Bool
    let attachmentFiles: [String: Data]

    var referencedAttachmentPaths: Set<String> {
        let receipts = budget.expenses.flatMap(\.receipts).compactMap(\.localRelativePath)
        let documentFiles = documents.flatMap(\.attachments).compactMap(\.localRelativePath)
        return Set(receipts + documentFiles)
    }

    func validateAttachmentCompleteness() throws {
        guard referencedAttachmentPaths.isSubset(of: Set(attachmentFiles.keys)) else {
            throw RelocationBackupError.incompleteAttachments
        }
    }
}

enum RelocationBackupError: LocalizedError {
    case incompleteAttachments

    var errorDescription: String? {
        "The selected backup is incomplete because one or more referenced attachments are missing."
    }
}

struct RelocationBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let backup: RelocationBackup

    init(backup: RelocationBackup) { self.backup = backup }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        backup = try JSONDecoder().decode(RelocationBackup.self, from: data)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}
