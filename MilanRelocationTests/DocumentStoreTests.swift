import XCTest
@testable import MilanRelocation

@MainActor
final class DocumentStoreTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testPastExpirationOverridesStoredStatus() {
        let document = makeDocument(status: .complete, expirationDate: date(2026, 8, 26))
        let now = date(2026, 8, 27)

        XCTAssertTrue(document.isExpired(referenceDate: now, calendar: calendar))
        XCTAssertEqual(document.effectiveStatus(referenceDate: now, calendar: calendar), .expired)
    }

    func testExpiringSoonUsesInclusiveWindowAndExcludesExpiredAndNotApplicable() {
        let now = date(2026, 8, 27)
        XCTAssertTrue(makeDocument(expirationDate: date(2026, 10, 26)).isExpiringSoon(referenceDate: now, calendar: calendar))
        XCTAssertFalse(makeDocument(expirationDate: date(2026, 10, 27)).isExpiringSoon(referenceDate: now, calendar: calendar))
        XCTAssertFalse(makeDocument(expirationDate: date(2026, 8, 26)).isExpiringSoon(referenceDate: now, calendar: calendar))
        XCTAssertFalse(makeDocument(status: .notApplicable, expirationDate: date(2026, 9, 1)).isExpiringSoon(referenceDate: now, calendar: calendar))
    }

    func testMissingStatusesRequireAction() {
        let now = date(2026, 8, 27)
        XCTAssertTrue(makeDocument(status: .notStarted).isMissing(referenceDate: now, calendar: calendar))
        XCTAssertTrue(makeDocument(status: .requested).isMissing(referenceDate: now, calendar: calendar))
        XCTAssertTrue(makeDocument(status: .translationNeeded).isMissing(referenceDate: now, calendar: calendar))
        XCTAssertFalse(makeDocument(status: .received).isMissing(referenceDate: now, calendar: calendar))
        XCTAssertFalse(makeDocument(status: .complete).isMissing(referenceDate: now, calendar: calendar))
        XCTAssertFalse(makeDocument(status: .notApplicable).isMissing(referenceDate: now, calendar: calendar))
    }

    func testCreateEditArchiveAndPersistence() {
        let persistence = MemoryDocumentPersistence()
        let store = DocumentStore(persistence: persistence)
        var document = makeDocument(name: "Marriage certificate", status: .requested)

        store.create(document)
        XCTAssertEqual(store.documents.count, 1)

        document.status = .received
        document.notes = "Apostille received"
        store.update(document, now: date(2026, 8, 27))
        XCTAssertEqual(store.documents.first?.status, .received)
        XCTAssertEqual(store.documents.first?.notes, "Apostille received")

        store.setArchived(true, id: document.id, now: date(2026, 8, 28))
        XCTAssertTrue(store.documents.first?.isArchived == true)

        let relaunched = DocumentStore(persistence: persistence)
        XCTAssertEqual(relaunched.documents, store.documents)
    }

    func testFiltersByOwnerCategoryAndEffectiveStatus() {
        let now = date(2026, 8, 27)
        let matching = RelocationDocument(
            name: "License", owner: .jeff, category: .nursing, status: .complete,
            expirationDate: date(2026, 8, 26)
        )
        let wrongOwner = RelocationDocument(name: "Passport", owner: .henry, category: .identity, status: .expired)
        let archived = RelocationDocument(name: "Old license", owner: .jeff, category: .nursing, status: .expired, isArchived: true)
        let store = DocumentStore(persistence: MemoryDocumentPersistence(), seedDocuments: [matching, wrongOwner, archived], calendar: calendar)

        let active = store.filtered(owner: .jeff, category: .nursing, status: .expired, includeArchived: false, referenceDate: now)
        XCTAssertEqual(active.map(\.id), [matching.id])

        let withArchived = store.filtered(owner: .jeff, category: .nursing, status: .expired, includeArchived: true, referenceDate: now)
        XCTAssertEqual(Set(withArchived.map(\.id)), Set([matching.id, archived.id]))
    }

    func testAttachmentMetadataPersistsWithoutFileContent() {
        let persistence = MemoryDocumentPersistence()
        let attachment = DocumentAttachmentMetadata(fileName: "passport.pdf", contentType: "application/pdf", byteCount: 42_000)
        let document = RelocationDocument(
            name: "Passport", owner: .henry, category: .identity, status: .complete,
            attachments: [attachment]
        )
        let store = DocumentStore(persistence: persistence, seedDocuments: [document])

        XCTAssertEqual(store.documents.first?.attachments, [attachment])
        XCTAssertEqual(persistence.documents?.first?.attachments.first?.fileName, "passport.pdf")
    }

    private func makeDocument(
        name: String = "Test document",
        status: DocumentStatus = .complete,
        expirationDate: Date? = nil
    ) -> RelocationDocument {
        RelocationDocument(
            name: name, owner: .both, category: .other, status: status, expirationDate: expirationDate
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

private final class MemoryDocumentPersistence: DocumentPersistence {
    var documents: [RelocationDocument]?
    func load() throws -> [RelocationDocument]? { documents }
    func save(_ documents: [RelocationDocument]) throws { self.documents = documents }
}
