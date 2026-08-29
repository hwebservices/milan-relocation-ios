import XCTest
@testable import MilanRelocation

final class GanttTimelineLayoutTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    func testDurationIncludesStartAndDueDates() {
        let task = makeTask(startDay: 10, dueDay: 16)
        let layout = makeLayout(mode: .week)

        XCTAssertEqual(layout.durationDays(for: task), 7)
        XCTAssertEqual(layout.barWidth(for: task), 7 * TimelineMode.week.dayWidth)
    }

    func testPositionUsesExactDayOffsetAtBothScales() {
        let date = day(11)
        let weekLayout = makeLayout(mode: .week)
        let monthLayout = makeLayout(mode: .month)

        XCTAssertEqual(weekLayout.xPosition(for: date), 10 * TimelineMode.week.dayWidth)
        XCTAssertEqual(monthLayout.xPosition(for: date), 10 * TimelineMode.month.dayWidth)
    }

    func testOverdueAndNoDateTimelineStates() {
        let referenceDate = day(20)
        let overdue = makeTask(startDay: 10, dueDay: 19, status: .inProgress)
        let complete = makeTask(startDay: 10, dueDay: 19, status: .complete)
        let noStart = RelocationTask(
            title: "No start",
            category: "Admin",
            owner: .both,
            status: .notStarted,
            dueDate: day(25)
        )
        let overdueNoStart = RelocationTask(
            title: "Late without start",
            category: "Admin",
            owner: .both,
            status: .blocked,
            dueDate: day(19)
        )
        let layout = makeLayout(mode: .month)

        XCTAssertEqual(layout.state(for: overdue, referenceDate: referenceDate), .overdue)
        XCTAssertEqual(layout.state(for: complete, referenceDate: referenceDate), .scheduled)
        XCTAssertEqual(layout.state(for: noStart, referenceDate: referenceDate), .noStartDate)
        XCTAssertEqual(layout.state(for: overdueNoStart, referenceDate: referenceDate), .overdueWithoutStartDate)
    }

    func testGeneratedRangeAlwaysIncludesFixedMoveMilestone() {
        let task = makeTask(startDay: 10, dueDay: 16)
        let layout = GanttTimelineLayout.make(tasks: [task], mode: .month, calendar: calendar)

        XCTAssertNotNil(layout)
        XCTAssertGreaterThanOrEqual(layout!.moveDate, layout!.startDate)
        XCTAssertLessThanOrEqual(layout!.moveDate, layout!.endDate)
    }

    private func makeLayout(mode: TimelineMode) -> GanttTimelineLayout {
        GanttTimelineLayout(startDate: day(1), endDate: day(31), mode: mode, calendar: calendar)
    }

    private func makeTask(startDay: Int, dueDay: Int, status: TaskStatus = .inProgress) -> RelocationTask {
        RelocationTask(
            title: "Timeline task",
            category: "Documents",
            owner: .henry,
            status: status,
            startDate: day(startDay),
            dueDate: day(dueDay)
        )
    }

    private func day(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: day))!
    }
}
