import SwiftUI

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: MRSpacing.xs) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(MRColor.accent)
            Text(title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(MRColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(MRColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SectionLabel: View {
    let title: String
    var action: String?

    var body: some View {
        HStack {
            Text(title).font(.headline).foregroundStyle(MRColor.ink)
            Spacer()
            if let action { Text(action).font(.caption.weight(.semibold)).foregroundStyle(MRColor.accent) }
        }
    }
}

struct StatusPill: View {
    let status: TaskStatus

    var body: some View {
        Text(status.title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(status.color)
            .background(status.color.opacity(0.11), in: Capsule())
    }
}

struct OwnerLabel: View {
    let owner: TaskOwner

    var body: some View {
        HStack(spacing: 6) {
            Text(owner.initials)
                .font(.caption2.weight(.bold))
                .frame(width: 26, height: 26)
                .foregroundStyle(Color.white)
                .background(MRColor.accent, in: Circle())
            Text(owner.rawValue).font(.caption.weight(.medium)).foregroundStyle(MRColor.secondaryText)
        }
    }
}

struct TaskRow: View {
    let task: RelocationTask

    var body: some View {
        HStack(alignment: .top, spacing: MRSpacing.md) {
            Image(systemName: task.status == .complete ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.status.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(task.title).font(.body.weight(.semibold)).foregroundStyle(MRColor.ink)
                HStack(spacing: 8) {
                    StatusPill(status: task.status)
                    OwnerLabel(owner: task.owner)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.dueDate.relocationShort).font(.caption.weight(.semibold))
                if task.isOverdue() {
                    Text("Overdue").font(.caption2.weight(.bold)).foregroundStyle(MRColor.red)
                }
            }
            .foregroundStyle(MRColor.secondaryText)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        let overdue = task.isOverdue() ? ", overdue" : ""
        return "\(task.title), \(task.status.title), owned by \(task.owner.rawValue), due \(task.dueDate.formatted(date: .long, time: .omitted))\(overdue)"
    }
}

struct MetricBlock: View {
    let label: String
    let value: String
    let detail: String
    var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.caption2.weight(.bold)).tracking(1).foregroundStyle(emphasized ? .white.opacity(0.75) : MRColor.secondaryText)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(emphasized ? .white : MRColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            Text(detail).font(.caption).foregroundStyle(emphasized ? .white.opacity(0.75) : MRColor.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(MRSpacing.md)
        .background(emphasized ? MRColor.accent : MRColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct MetricGrid<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let compactColumnCount: Int
    @ViewBuilder let content: Content

    init(columns: Int, @ViewBuilder content: () -> Content) {
        compactColumnCount = columns
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: MRSpacing.sm) {
            content
        }
    }

    private var gridColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : compactColumnCount
        return Array(repeating: GridItem(.flexible(), spacing: MRSpacing.sm), count: count)
    }
}

enum ContentStateKind { case empty, loading, error }

struct ContentStateView: View {
    let kind: ContentStateKind
    let title: String
    let detail: String

    var icon: String {
        switch kind { case .empty: "tray"; case .loading: "clock"; case .error: "exclamationmark.triangle" }
    }

    var body: some View {
        VStack(spacing: 12) {
            if kind == .loading { ProgressView().tint(MRColor.accent) }
            else { Image(systemName: icon).font(.title).foregroundStyle(kind == .error ? MRColor.red : MRColor.accent) }
            Text(title).font(.headline).foregroundStyle(MRColor.ink)
            Text(detail).font(.subheadline).foregroundStyle(MRColor.secondaryText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MRSpacing.xl)
        .background(MRColor.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
