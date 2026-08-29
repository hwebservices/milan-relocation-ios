import XCTest
@testable import MilanRelocation

@MainActor
final class TaskStoreTests: XCTestCase {
    func testCreatesTaskAndPersistsIt() {
        let persistence = MemoryTaskPersistence()
        let store = TaskStore(persistence: persistence)
        let task = makeTask(title: "Find an apartment")

        store.create(task)

        XCTAssertEqual(store.tasks, [task])
        XCTAssertEqual(persistence.storedTasks, [task])
    }

    func testEditsExistingTask() {
        let original = makeTask(title: "Draft application")
        let store = TaskStore(persistence: MemoryTaskPersistence(), seedTasks: [original])
        var edited = original
        edited.title = "Submit application"
        edited.owner = .jeff
        edited.priority = .urgent
        edited.notes = "Include translated records."

        store.update(edited)

        XCTAssertEqual(store.tasks.first?.title, "Submit application")
        XCTAssertEqual(store.tasks.first?.owner, .jeff)
        XCTAssertEqual(store.tasks.first?.priority, .urgent)
        XCTAssertEqual(store.tasks.first?.notes, "Include translated records.")
    }

    func testDeletesTask() {
        let task = makeTask(title: "Remove me")
        let persistence = MemoryTaskPersistence()
        let store = TaskStore(persistence: persistence, seedTasks: [task])

        store.delete(id: task.id)

        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertEqual(persistence.storedTasks, [])
    }

    func testFiltersByStatusAndOwnerTogether() {
        let matching = makeTask(title: "Matching", owner: .henry, status: .blocked)
        let wrongOwner = makeTask(title: "Wrong owner", owner: .jeff, status: .blocked)
        let wrongStatus = makeTask(title: "Wrong status", owner: .henry, status: .complete)
        let store = TaskStore(persistence: MemoryTaskPersistence(), seedTasks: [matching, wrongOwner, wrongStatus])

        let results = store.filtered(status: .blocked, owner: .henry)

        XCTAssertEqual(results, [matching])
    }

    func testLoadsPreviouslySavedTasksOnRelaunch() {
        let persistence = MemoryTaskPersistence()
        let firstStore = TaskStore(persistence: persistence)
        let task = makeTask(title: "Persisted task")
        firstStore.create(task)

        let relaunchedStore = TaskStore(persistence: persistence)

        XCTAssertEqual(relaunchedStore.tasks, [task])
    }

    private func makeTask(
        title: String,
        owner: TaskOwner = .both,
        status: TaskStatus = .notStarted
    ) -> RelocationTask {
        RelocationTask(
            title: title,
            category: "Test",
            owner: owner,
            status: status,
            priority: .medium,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            dueDate: Date(timeIntervalSince1970: 1_700_086_400),
            notes: nil
        )
    }
}

private final class MemoryTaskPersistence: TaskPersistence {
    var storedTasks: [RelocationTask]?

    func load() throws -> [RelocationTask]? { storedTasks }
    func save(_ tasks: [RelocationTask]) throws { storedTasks = tasks }
}
