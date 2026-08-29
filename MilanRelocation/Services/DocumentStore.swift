import Foundation
import Observation

protocol DocumentPersistence: AnyObject {
    func load() throws -> [RelocationDocument]?
    func save(_ documents: [RelocationDocument]) throws
}

final class FileDocumentPersistence: DocumentPersistence {
    private let fileURL: URL

    init(fileURL: URL) { self.fileURL = fileURL }

    static func live(environment: [String: String] = ProcessInfo.processInfo.environment) -> FileDocumentPersistence {
        let manager = FileManager.default
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("MilanRelocation", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = environment["MILAN_UI_TESTING"] == "1" ? "ui-test-documents.json" : "documents.json"
        return FileDocumentPersistence(fileURL: directory.appendingPathComponent(fileName))
    }

    func load() throws -> [RelocationDocument]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try JSONDecoder().decode([RelocationDocument].self, from: Data(contentsOf: fileURL))
    }

    func save(_ documents: [RelocationDocument]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(documents).write(to: fileURL, options: .atomic)
    }
}

@MainActor
@Observable
final class DocumentStore {
    private(set) var documents: [RelocationDocument]
    private(set) var isLoading = false
    private(set) var error: String?

    private let persistence: DocumentPersistence
    private let calendar: Calendar

    init(
        persistence: DocumentPersistence,
        seedDocuments: [RelocationDocument] = [],
        calendar: Calendar = .current
    ) {
        self.persistence = persistence
        self.calendar = calendar
        documents = seedDocuments
        load()
    }

    static func live(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> DocumentStore {
        let persistence = FileDocumentPersistence.live(environment: environment)
        let seed = environment["MILAN_UI_TESTING"] == "1" ? sampleDocuments(calendar: calendar, now: now) : []
        if environment["MILAN_RESET_DOCUMENTS"] == "1" { try? persistence.save(seed) }
        return DocumentStore(persistence: persistence, seedDocuments: seed, calendar: calendar)
    }

    func create(_ document: RelocationDocument) {
        documents.append(document)
        commit()
    }

    func update(_ document: RelocationDocument, now: Date = .now) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        var updated = document
        updated.updatedAt = now
        documents[index] = updated
        commit()
    }

    func setArchived(_ isArchived: Bool, id: UUID, now: Date = .now) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[index].isArchived = isArchived
        documents[index].updatedAt = now
        commit()
    }

    func replaceAll(with documents: [RelocationDocument]) { self.documents = documents; commit() }

    func filtered(
        owner: TaskOwner?,
        category: DocumentCategory?,
        status: DocumentStatus?,
        includeArchived: Bool,
        referenceDate: Date = .now
    ) -> [RelocationDocument] {
        documents.filter { document in
            (includeArchived || !document.isArchived)
                && (owner == nil || document.owner == owner)
                && (category == nil || document.category == category)
                && (status == nil || document.effectiveStatus(referenceDate: referenceDate, calendar: calendar) == status)
        }
    }

    func missing(referenceDate: Date = .now) -> [RelocationDocument] {
        documents.filter { !$0.isArchived && $0.isMissing(referenceDate: referenceDate, calendar: calendar) }
    }

    func expiringSoon(referenceDate: Date = .now, withinDays: Int = 60) -> [RelocationDocument] {
        documents.filter {
            !$0.isArchived && $0.isExpiringSoon(referenceDate: referenceDate, withinDays: withinDays, calendar: calendar)
        }
    }

    func expired(referenceDate: Date = .now) -> [RelocationDocument] {
        documents.filter { !$0.isArchived && $0.isExpired(referenceDate: referenceDate, calendar: calendar) }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            if let saved = try persistence.load() {
                documents = saved
            } else {
                try persistence.save(documents)
            }
            sortDocuments()
            error = nil
        } catch {
            self.error = "Documents could not be loaded. Please try again."
        }
    }

    private func commit() {
        sortDocuments()
        do {
            try persistence.save(documents)
            error = nil
        } catch {
            self.error = "Document changes could not be saved on this device."
        }
    }

    private func sortDocuments() {
        documents.sort { lhs, rhs in
            if lhs.isArchived != rhs.isArchived { return !lhs.isArchived }
            if lhs.effectiveStatus(calendar: calendar) != rhs.effectiveStatus(calendar: calendar) {
                return lhs.effectiveStatus(calendar: calendar).rawValue < rhs.effectiveStatus(calendar: calendar).rawValue
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    static func sampleDocuments(calendar: Calendar = .current, now: Date = .now) -> [RelocationDocument] {
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now) ?? now }
        return [
            RelocationDocument(
                name: "Henry passport", owner: .henry, category: .identity, status: .complete,
                issueDate: day(-900), expirationDate: day(760), requiredFor: "Elective residence visa",
                sourceInformation: "U.S. Department of State"
            ),
            RelocationDocument(
                name: "Jeff nursing diploma", owner: .jeff, category: .nursing, status: .translationNeeded,
                issueDate: day(-2_500), requiredFor: "Italian nursing qualification recognition",
                notes: "Obtain a certified Italian translation.", sourceInformation: "University registrar"
            ),
            RelocationDocument(
                name: "Apostilled marriage certificate", owner: .both, category: .residency, status: .requested,
                requiredFor: "Family residency application", notes: "County request submitted online."
            ),
            RelocationDocument(
                name: "Jeff professional license", owner: .jeff, category: .nursing, status: .received,
                issueDate: day(-330), expirationDate: day(35), requiredFor: "Italian nursing qualification recognition",
                sourceInformation: "State nursing board"
            ),
            RelocationDocument(
                name: "Employment verification letter", owner: .henry, category: .employment, status: .received,
                issueDate: day(-30), requiredFor: "Apartment applications", sourceInformation: "Employer HR"
            ),
            RelocationDocument(
                name: "Expired bank reference", owner: .both, category: .financial, status: .complete,
                issueDate: day(-400), expirationDate: day(-5), requiredFor: "Apartment applications"
            )
        ]
    }
}
