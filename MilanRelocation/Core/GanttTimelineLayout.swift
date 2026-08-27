import CoreGraphics
import Foundation

enum TimelineMode: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: Self { self }
    var calendarComponent: Calendar.Component { self == .week ? .weekOfYear : .month }
    var dayWidth: CGFloat { self == .week ? 14 : 4.5 }
}

enum GanttTaskTimelineState: Equatable {
    case scheduled
    case overdue
    case noStartDate
    case overdueWithoutStartDate
}

struct GanttTimelineLayout {
    static let moveDateComponents = DateComponents(year: 2027, month: 1, day: 28)

    let startDate: Date
    let endDate: Date
    let mode: TimelineMode
    let calendar: Calendar

    static func make(
        tasks: [RelocationTask],
        mode: TimelineMode,
        calendar: Calendar = .current
    ) -> GanttTimelineLayout? {
        let scheduledTasks = tasks.filter { $0.startDate != nil }
        guard let firstTaskDate = scheduledTasks.compactMap(\.startDate).min() else { return nil }

        let moveDate = calendar.date(from: moveDateComponents)!
        let lastTaskDate = scheduledTasks.map(\.dueDate).max() ?? firstTaskDate
        let earliest = min(firstTaskDate, moveDate)
        let latest = max(lastTaskDate, moveDate)
        let component = mode.calendarComponent
        let paddedStart = calendar.dateInterval(of: component, for: earliest)?.start ?? earliest
        let intervalEnd = calendar.dateInterval(of: component, for: latest)?.end ?? latest
        let paddedEnd = calendar.date(byAdding: .day, value: -1, to: intervalEnd) ?? latest

        return GanttTimelineLayout(startDate: paddedStart, endDate: paddedEnd, mode: mode, calendar: calendar)
    }

    var moveDate: Date { calendar.date(from: Self.moveDateComponents)! }
    var totalDays: Int { dayDistance(from: startDate, to: endDate) + 1 }
    var chartWidth: CGFloat { CGFloat(totalDays) * mode.dayWidth }

    var tickDates: [Date] {
        var dates: [Date] = []
        var date = startDate
        while date <= endDate {
            dates.append(date)
            guard let next = calendar.date(byAdding: mode.calendarComponent, value: 1, to: date) else { break }
            date = next
        }
        return dates
    }

    func durationDays(for task: RelocationTask) -> Int? {
        guard let taskStart = task.startDate else { return nil }
        return max(dayDistance(from: taskStart, to: task.dueDate) + 1, 1)
    }

    func xPosition(for date: Date) -> CGFloat {
        let days = min(max(dayDistance(from: startDate, to: date), 0), totalDays)
        return CGFloat(days) * mode.dayWidth
    }

    func barWidth(for task: RelocationTask) -> CGFloat? {
        guard let duration = durationDays(for: task) else { return nil }
        return CGFloat(duration) * mode.dayWidth
    }

    func state(for task: RelocationTask, referenceDate: Date = .now) -> GanttTaskTimelineState {
        let overdue = task.isOverdue(referenceDate: referenceDate, calendar: calendar)
        if task.startDate == nil { return overdue ? .overdueWithoutStartDate : .noStartDate }
        return overdue ? .overdue : .scheduled
    }

    private func dayDistance(from start: Date, to end: Date) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: end)
        ).day ?? 0
    }
}
