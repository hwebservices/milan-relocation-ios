import XCTest
@testable import MilanRelocation

@MainActor
final class RelocationBackupTests: XCTestCase {
    func testBackupRoundTripIncludesAttachmentBytesAndPreferences() throws {
        let backup = RelocationBackup(
            formatVersion: 1,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            tasks: [],
            budget: BudgetData(expenses: [], targets: [], funding: RelocationFunding(relocationCash: 10, deposits: 20, emergencyReserve: 30)),
            housing: HousingStore.emptyData,
            documents: [],
            contacts: [ContactItem(name: "Mario", role: "Agent", organization: "Casa", email: "mario@example.com")],
            weeklyReviews: [],
            showCompletedTasks: false,
            attachmentFiles: ["receipt.pdf": Data("pdf".utf8)]
        )
        let decoded = try JSONDecoder().decode(RelocationBackup.self, from: JSONEncoder().encode(backup))
        XCTAssertEqual(decoded.formatVersion, 1)
        XCTAssertEqual(decoded.contacts.first?.name, "Mario")
        XCTAssertEqual(decoded.attachmentFiles["receipt.pdf"], Data("pdf".utf8))
        XCTAssertFalse(decoded.showCompletedTasks)
    }

    func testBackupRejectsMissingReferencedAttachment() throws {
        let receipt = ReceiptAttachment(displayName: "receipt.pdf", localRelativePath: "receipt.pdf")
        let expense = Expense(name: "Deposit", amount: 100, date: .now, category: .moving, owner: .both, recurrence: .oneTime, receipts: [receipt])
        let backup = RelocationBackup(
            formatVersion: 1,
            createdAt: .now,
            tasks: [],
            budget: BudgetData(expenses: [expense], targets: [], funding: RelocationFunding(relocationCash: 0, deposits: 0, emergencyReserve: 0)),
            housing: HousingStore.emptyData,
            documents: [],
            contacts: [],
            weeklyReviews: [],
            showCompletedTasks: true,
            attachmentFiles: [:]
        )

        XCTAssertThrowsError(try backup.validateAttachmentCompleteness())
    }
}
