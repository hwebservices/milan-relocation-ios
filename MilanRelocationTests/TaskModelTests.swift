import XCTest
@testable import MilanRelocation

final class TaskModelTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testAllTaskStatusesHaveDistinctTitles() {
        XCTAssertEqual(TaskStatus.allCases.count, 6)
        XCTAssertEqual(Set(TaskStatus.allCases.map(\.title)).count, 6)
        XCTAssertEqual(TaskStatus.waitingForResponse.title, "Waiting for response")
    }

    func testCompleteAndCancelledAreTerminal() {
        XCTAssertTrue(TaskStatus.complete.isTerminal)
        XCTAssertTrue(TaskStatus.cancelled.isTerminal)
        XCTAssertFalse(TaskStatus.blocked.isTerminal)
    }

    func testPastIncompleteTaskIsOverdue() {
        let due = calendar.date(byAdding: .day, value: -1, to: referenceDate)!
        let task = RelocationTask(title: "Test", category: "Admin", owner: .both, status: .inProgress, dueDate: due)
        XCTAssertTrue(task.isOverdue(referenceDate: referenceDate, calendar: calendar))
    }

    func testTodayIsNotOverdue() {
        let task = RelocationTask(title: "Test", category: "Admin", owner: .henry, status: .notStarted, dueDate: referenceDate)
        XCTAssertFalse(task.isOverdue(referenceDate: referenceDate, calendar: calendar))
    }

    func testTerminalTasksAreNeverOverdue() {
        let due = calendar.date(byAdding: .day, value: -10, to: referenceDate)!
        for status in [TaskStatus.complete, .cancelled] {
            let task = RelocationTask(title: "Test", category: "Admin", owner: .jeff, status: status, dueDate: due)
            XCTAssertFalse(task.isOverdue(referenceDate: referenceDate, calendar: calendar))
        }
    }
}

