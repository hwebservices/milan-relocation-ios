import Foundation
import Observation

protocol TaskPersistence {
    func load() throws -> [RelocationTask]?
    func save(_ tasks: [RelocationTask]) throws
}

struct FileTaskPersistence: TaskPersistence {
    let url: URL

    func load() throws -> [RelocationTask]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode([RelocationTask].self, from: Data(contentsOf: url))
    }

    func save(_ tasks: [RelocationTask]) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(tasks)
        try data.write(to: url, options: .atomic)
    }

    static func appStorage(environment: [String: String] = ProcessInfo.processInfo.environment) -> FileTaskPersistence {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let isUITesting = environment["MILAN_UI_TESTING"] == "1"
        return FileTaskPersistence(url: directory.appendingPathComponent(isUITesting ? "ui-test-tasks.json" : "tasks.json"))
    }
}

@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [RelocationTask]
    private(set) var lastErrorMessage: String?

    private let persistence: TaskPersistence

    init(persistence: TaskPersistence, seedTasks: [RelocationTask] = []) {
        self.persistence = persistence
        do {
            if let savedTasks = try persistence.load() {
                tasks = savedTasks
            } else {
                tasks = seedTasks
                try persistence.save(seedTasks)
            }
        } catch {
            tasks = seedTasks
            lastErrorMessage = "Tasks could not be loaded. Your changes may not persist."
        }
        sortTasks()
    }

    static func live(
        calendar: Calendar = .current,
        now: Date = .now,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> TaskStore {
        let persistence = FileTaskPersistence.appStorage(environment: environment)
        if environment["MILAN_RESET_TASKS"] == "1" {
            try? FileManager.default.removeItem(at: persistence.url)
        }
        return TaskStore(persistence: persistence, seedTasks: sampleTasks(calendar: calendar, now: now))
    }

    func create(_ task: RelocationTask) {
        tasks.append(task)
        commit()
    }

    func update(_ task: RelocationTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        commit()
    }

    func delete(id: UUID) {
        tasks.removeAll { $0.id == id }
        commit()
    }

    func filtered(status: TaskStatus?, owner: TaskOwner?) -> [RelocationTask] {
        tasks.filter { task in
            (status == nil || task.status == status) &&
            (owner == nil || task.owner == owner)
        }
    }

    private func commit() {
        sortTasks()
        do {
            try persistence.save(tasks)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Tasks could not be saved. Please try again."
        }
    }

    private func sortTasks() {
        tasks.sort {
            if $0.status.isTerminal != $1.status.isTerminal { return !$0.status.isTerminal }
            if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
            return $0.priority.sortOrder > $1.priority.sortOrder
        }
    }

    static func sampleTasks(calendar: Calendar = .current, now: Date = .now) -> [RelocationTask] {
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now) ?? now }
        return [
            RelocationTask(title: "Confirm temporary apartment in Porta Romana", category: "Housing", owner: .both, status: .inProgress, priority: .urgent, startDate: day(-5), dueDate: day(2), notes: "Compare cancellation terms before signing."),
            RelocationTask(title: "Request apostilled marriage certificate", category: "Documents", owner: .henry, status: .waitingForResponse, priority: .high, startDate: day(-14), dueDate: day(-3)),
            RelocationTask(title: "Submit codice fiscale applications", category: "Documents", owner: .both, status: .notStarted, priority: .high, startDate: day(3), dueDate: day(7)),
            RelocationTask(title: "Shortlist Italian language programs", category: "Education & Work", owner: .jeff, status: .inProgress, priority: .medium, startDate: day(-2), dueDate: day(5)),
            RelocationTask(title: "Review international health coverage", category: "Admin", owner: .henry, status: .blocked, priority: .urgent, dueDate: day(1)),
            RelocationTask(title: "Create first-month arrival budget", category: "Budget", owner: .jeff, status: .complete, priority: .medium, dueDate: day(-2)),
            RelocationTask(title: "Book exploratory housing trip", category: "Travel", owner: .both, status: .cancelled, priority: .low, dueDate: day(14))
        ]
    }
}
