import Foundation

struct WeeklyReviewEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var weekOf: Date
    var progress: String
    var blockers: String
    var priorities: String
    var updatedAt: Date

    init(id: UUID = UUID(), weekOf: Date, progress: String, blockers: String, priorities: String, updatedAt: Date = .now) {
        self.id = id; self.weekOf = weekOf; self.progress = progress; self.blockers = blockers; self.priorities = priorities; self.updatedAt = updatedAt
    }
}
