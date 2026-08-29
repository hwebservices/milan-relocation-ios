import Foundation
import Observation

protocol WeeklyReviewPersistence { func load() throws -> [WeeklyReviewEntry]?; func save(_ entries: [WeeklyReviewEntry]) throws }

struct FileWeeklyReviewPersistence: WeeklyReviewPersistence {
    let url: URL
    func load() throws -> [WeeklyReviewEntry]? { guard FileManager.default.fileExists(atPath: url.path) else { return nil }; return try JSONDecoder().decode([WeeklyReviewEntry].self, from: Data(contentsOf: url)) }
    func save(_ entries: [WeeklyReviewEntry]) throws { try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true); try JSONEncoder().encode(entries).write(to: url, options: .atomic) }
    static func appStorage(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let name = environment["MILAN_UI_TESTING"] == "1" ? "ui-test-weekly-reviews.json" : "weekly-reviews.json"
        return Self(url: base.appendingPathComponent("MilanRelocation", isDirectory: true).appendingPathComponent(name))
    }
}

@MainActor @Observable
final class WeeklyReviewStore {
    private(set) var entries: [WeeklyReviewEntry]
    private(set) var error: String?
    private let persistence: WeeklyReviewPersistence
    init(persistence: WeeklyReviewPersistence) {
        self.persistence = persistence
        do { entries = try persistence.load() ?? [] } catch { entries = []; self.error = "Weekly reviews could not be loaded." }
        sort()
    }
    static func live(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self {
        let persistence = FileWeeklyReviewPersistence.appStorage(environment: environment)
        if environment["MILAN_RESET_WEEKLY_REVIEWS"] == "1" { try? FileManager.default.removeItem(at: persistence.url) }
        return Self(persistence: persistence)
    }
    func save(_ entry: WeeklyReviewEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) { entries[index] = entry } else { entries.append(entry) }
        commit()
    }
    func delete(id: UUID) { entries.removeAll { $0.id == id }; commit() }
    func replaceAll(with entries: [WeeklyReviewEntry]) { self.entries = entries; commit() }
    private func commit() { sort(); do { try persistence.save(entries); error = nil } catch { self.error = "Weekly review could not be saved." } }
    private func sort() { entries.sort { $0.weekOf > $1.weekOf } }
}
