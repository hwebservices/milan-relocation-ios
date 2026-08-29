import XCTest
@testable import MilanRelocation

@MainActor
final class WeeklyReviewStoreTests: XCTestCase {
    func testSaveEditDeleteAndPersistence() {
        let persistence = MemoryWeeklyReviewPersistence()
        let store = WeeklyReviewStore(persistence: persistence)
        var entry = WeeklyReviewEntry(weekOf: Date(timeIntervalSince1970: 1_700_000_000), progress: "Visa submitted", blockers: "Waiting", priorities: "Housing")
        store.save(entry)
        XCTAssertEqual(persistence.entries, [entry])
        entry.blockers = "None"
        store.save(entry)
        XCTAssertEqual(store.entries.first?.blockers, "None")
        let relaunched = WeeklyReviewStore(persistence: persistence)
        XCTAssertEqual(relaunched.entries.first?.progress, "Visa submitted")
        relaunched.delete(id: entry.id)
        XCTAssertTrue(relaunched.entries.isEmpty)
    }
}

private final class MemoryWeeklyReviewPersistence: WeeklyReviewPersistence {
    var entries: [WeeklyReviewEntry]?
    func load() throws -> [WeeklyReviewEntry]? { entries }
    func save(_ entries: [WeeklyReviewEntry]) throws { self.entries = entries }
}
