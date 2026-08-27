import SwiftUI

struct TimelineView: View {
    @Environment(MockRelocationStore.self) private var store

    private var rangeStart: Date { store.timeline.map(\.startDate).min() ?? .now }
    private var rangeEnd: Date { store.timeline.map(\.endDate).max() ?? .now }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Move plan", title: "Timeline", detail: "A high-level path from preparation to feeling at home.")
                HStack {
                    Text(rangeStart.relocationShort)
                    Spacer()
                    Text("Today")
                    Spacer()
                    Text(rangeEnd.relocationShort)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MRColor.secondaryText)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Timeline from \(rangeStart.formatted(date: .long, time: .omitted)) through \(rangeEnd.formatted(date: .long, time: .omitted))")

                ForEach(store.timeline) { item in
                    TimelineBar(item: item, rangeStart: rangeStart, rangeEnd: rangeEnd)
                }
            }
            .relocationPage()
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TimelineBar: View {
    let item: TimelineItem
    let rangeStart: Date
    let rangeEnd: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.headline)
                    Text("\(item.startDate.relocationShort) – \(item.endDate.relocationShort)").font(.caption).foregroundStyle(MRColor.secondaryText)
                }
                Spacer()
                OwnerLabel(owner: item.owner)
            }
            GeometryReader { proxy in
                let totalInterval = max(rangeEnd.timeIntervalSince(rangeStart), 1)
                let startRatio = min(max(item.startDate.timeIntervalSince(rangeStart) / totalInterval, 0), 1)
                let durationRatio = min(max(item.endDate.timeIntervalSince(item.startDate) / totalInterval, 0), 1 - startRatio)
                let phaseWidth = max(proxy.size.width * durationRatio, 12)
                ZStack(alignment: .leading) {
                    Capsule().fill(MRColor.divider)
                    Capsule()
                        .fill(MRColor.accentSoft)
                        .frame(width: phaseWidth)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(MRColor.accent)
                                .frame(width: phaseWidth * min(max(item.progress, 0), 1))
                        }
                        .offset(x: proxy.size.width * startRatio)
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, MRSpacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title), \(item.startDate.formatted(date: .long, time: .omitted)) to \(item.endDate.formatted(date: .long, time: .omitted)), owned by \(item.owner.rawValue), \(Int(item.progress * 100)) percent complete")
    }
}
