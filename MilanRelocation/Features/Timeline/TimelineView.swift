import SwiftUI

private struct TimelineEditorContext: Identifiable {
    let id = UUID()
    let task: RelocationTask
}

struct TimelineView: View {
    @Environment(TaskStore.self) private var taskStore
    @State private var mode: TimelineMode = .month
    @State private var editorContext: TimelineEditorContext?

    private var scheduledTasks: [RelocationTask] { taskStore.tasks.filter { $0.startDate != nil } }
    private var unscheduledTasks: [RelocationTask] { taskStore.tasks.filter { $0.startDate == nil } }
    private var layout: GanttTimelineLayout? { .make(tasks: taskStore.tasks, mode: mode) }
    private var workstreams: [(name: String, tasks: [RelocationTask])] {
        Dictionary(grouping: scheduledTasks, by: \.category)
            .map { (name: $0.key, tasks: $0.value.sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(
                    eyebrow: "Move plan",
                    title: "Timeline",
                    detail: "Live task timing by workstream, anchored to the move to Milan."
                )

                if taskStore.tasks.isEmpty {
                    ContentStateView(
                        kind: .empty,
                        title: "No timeline tasks",
                        detail: "Create a task with start and due dates to begin the move plan."
                    )
                    .accessibilityIdentifier("timeline-empty-state")
                } else {
                    Picker("Timeline scale", selection: $mode) {
                        ForEach(TimelineMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("timeline-mode-picker")

                    if let layout {
                        liveTimeline(layout: layout)
                            .animation(.easeInOut(duration: 0.22), value: mode)
                    } else {
                        ContentStateView(
                            kind: .empty,
                            title: "Tasks need start dates",
                            detail: "Add a start date to place work accurately on the timeline."
                        )
                        .accessibilityIdentifier("timeline-no-dates-state")
                    }

                    if !unscheduledTasks.isEmpty {
                        unscheduledSection
                    }
                }
            }
            .relocationPage()
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorContext) { context in
            TaskEditorView(task: context.task)
                .environment(taskStore)
        }
    }

    private func liveTimeline(layout: GanttTimelineLayout) -> some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            HStack(spacing: MRSpacing.md) {
                Label("Move: Jan 28, 2027", systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MRColor.accent)
                    .accessibilityIdentifier("timeline-move-milestone")
                Spacer()
                Text("\(scheduledTasks.count) scheduled")
                    .font(.caption)
                    .foregroundStyle(MRColor.secondaryText)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    GanttAxisView(layout: layout)
                    ForEach(workstreams, id: \.name) { workstream in
                        Text(workstream.name.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(MRColor.secondaryText)
                            .padding(.top, MRSpacing.md)
                            .padding(.bottom, MRSpacing.xs)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(workstream.tasks) { task in
                            GanttTaskRow(task: task, layout: layout) {
                                editorContext = TimelineEditorContext(task: task)
                            }
                            Divider().overlay(MRColor.divider)
                        }
                    }
                }
                .frame(width: 190 + layout.chartWidth, alignment: .leading)
            }
            .accessibilityIdentifier("timeline-chart")
        }
    }

    private var unscheduledSection: some View {
        VStack(alignment: .leading, spacing: MRSpacing.sm) {
            SectionLabel(title: "Needs scheduling", action: "\(unscheduledTasks.count) tasks")
            Text("These tasks have due dates but no start dates, so their duration cannot be plotted yet.")
                .font(.subheadline)
                .foregroundStyle(MRColor.secondaryText)
            LazyVStack(spacing: 0) {
                ForEach(unscheduledTasks) { task in
                    Button {
                        editorContext = TimelineEditorContext(task: task)
                    } label: {
                        TaskRow(task: task)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("timeline-unscheduled-task-\(task.id.uuidString)")
                    Divider().overlay(MRColor.divider)
                }
            }
        }
        .accessibilityIdentifier("timeline-no-date-tasks")
    }
}

private struct GanttAxisView: View {
    let layout: GanttTimelineLayout

    var body: some View {
        HStack(spacing: 0) {
            Text("WORKSTREAM")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(MRColor.secondaryText)
                .frame(width: 190, alignment: .leading)

            ZStack(alignment: .topLeading) {
                Rectangle().fill(MRColor.divider).frame(height: 1)
                ForEach(layout.tickDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(tickLabel(date))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(MRColor.secondaryText)
                            .fixedSize()
                        Rectangle().fill(MRColor.divider).frame(width: 1, height: 14)
                    }
                    .offset(x: layout.xPosition(for: date))
                }

                Rectangle()
                    .fill(MRColor.accent)
                    .frame(width: 2, height: 36)
                    .offset(x: layout.xPosition(for: layout.moveDate))
                    .accessibilityHidden(true)
            }
            .frame(width: layout.chartWidth, height: 36, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(layout.mode.rawValue) timeline from \(layout.startDate.formatted(date: .long, time: .omitted)) through \(layout.endDate.formatted(date: .long, time: .omitted)), with move milestone January 28, 2027")
    }

    private func tickLabel(_ date: Date) -> String {
        layout.mode == .week
            ? date.formatted(.dateTime.month(.abbreviated).day())
            : date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
    }
}

private struct GanttTaskRow: View {
    let task: RelocationTask
    let layout: GanttTimelineLayout
    let action: () -> Void

    private var startDate: Date { task.startDate ?? task.dueDate }
    private var overdue: Bool { layout.state(for: task) == .overdue }
    private var barWidth: CGFloat { layout.barWidth(for: task) ?? layout.mode.dayWidth }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MRColor.ink)
                    .lineLimit(2)
                Text("\(startDate.relocationShort) – \(task.dueDate.relocationShort)")
                    .font(.caption2)
                    .foregroundStyle(MRColor.secondaryText)
                if overdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(MRColor.red)
                }
            }
            .frame(width: 174, alignment: .leading)
            .frame(minHeight: 64, alignment: .leading)
            .padding(.trailing, 16)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(MRColor.accent.opacity(0.38))
                    .frame(width: 2, height: 64)
                    .offset(x: layout.xPosition(for: layout.moveDate))
                    .accessibilityHidden(true)

                Button(action: action) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(task.status.color.opacity(task.status == .cancelled ? 0.35 : 0.9))
                            .frame(width: barWidth, height: 24)
                            .overlay {
                                if overdue {
                                    Capsule().stroke(MRColor.red, lineWidth: 3)
                                }
                            }
                        if barWidth >= 76 {
                            Text(task.status.title)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: max(barWidth, 44), height: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .offset(x: layout.xPosition(for: startDate))
                .accessibilityIdentifier("timeline-task-\(task.id.uuidString)")
                .accessibilityLabel(accessibilitySummary)
                .accessibilityHint("Opens task editor")
            }
            .frame(width: layout.chartWidth, alignment: .leading)
            .frame(minHeight: 64, alignment: .leading)
        }
    }

    private var accessibilitySummary: String {
        let duration = layout.durationDays(for: task) ?? 0
        let overdueSummary = overdue ? ", overdue" : ""
        return "\(task.title), \(task.category), \(task.status.title), \(duration) days, from \(startDate.formatted(date: .long, time: .omitted)) through \(task.dueDate.formatted(date: .long, time: .omitted)), owned by \(task.owner.rawValue)\(overdueSummary)"
    }
}
