import SwiftUI

struct WeeklyReviewView: View {
    @Environment(MockRelocationStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Friday ritual", title: "Weekly Review", detail: "A shared checkpoint for progress, blockers, and next week.")
                MetricBlock(label: "Completed", value: "\(store.tasks.filter { $0.status == .complete }.count)", detail: "tasks this plan", emphasized: true)
                reviewPrompt(number: "01", title: "What moved forward?", detail: "Capture decisions and completed work.")
                reviewPrompt(number: "02", title: "What is blocked?", detail: "Name the dependency and the next person to contact.")
                reviewPrompt(number: "03", title: "What matters next week?", detail: "Choose no more than three shared priorities.")
            }.relocationPage()
        }.navigationTitle("Weekly Review")
    }

    private func reviewPrompt(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: MRSpacing.md) {
            Text(number).font(.system(.title2, design: .serif, weight: .bold)).foregroundStyle(MRColor.accent)
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(detail).font(.subheadline).foregroundStyle(MRColor.secondaryText) }
            Spacer()
        }.padding(.vertical, 12)
    }
}

