import SwiftUI

struct TimelineView: View {
    @Environment(MockRelocationStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Move plan", title: "Timeline", detail: "A high-level path from preparation to feeling at home.")
                HStack {
                    ForEach(["Now", "+30d", "+60d", "+90d"], id: \.self) { label in
                        Text(label).font(.caption2.weight(.semibold)).foregroundStyle(MRColor.secondaryText).frame(maxWidth: .infinity)
                    }
                }
                ForEach(store.timeline) { item in TimelineBar(item: item) }
                ContentStateView(kind: .loading, title: "Detailed dependencies coming next", detail: "This foundation shows local planning data while shared synchronization is intentionally deferred.")
            }
            .relocationPage()
        }
        .navigationTitle("Timeline")
    }
}

private struct TimelineBar: View {
    let item: TimelineItem

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
                ZStack(alignment: .leading) {
                    Capsule().fill(MRColor.divider)
                    Capsule().fill(MRColor.accent).frame(width: proxy.size.width * min(max(item.progress, 0), 1))
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, MRSpacing.sm)
    }
}

