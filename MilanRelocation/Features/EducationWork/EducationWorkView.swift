import SwiftUI

struct EducationWorkView: View {
    @Environment(MockRelocationStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Next chapter", title: "Education & Work", detail: "Coordinate professional transitions and language learning.")
                SectionLabel(title: "In motion")
                ForEach(store.tasks.filter { $0.category == "Education & Work" }) { TaskRow(task: $0) }
                HStack(alignment: .top, spacing: MRSpacing.md) {
                    Image(systemName: "text.bubble.fill").font(.title).foregroundStyle(MRColor.accent)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Italian study goal").font(.headline)
                        Text("Reach conversational A2 before the move, with two guided sessions each week.").font(.subheadline).foregroundStyle(MRColor.secondaryText)
                    }
                }.padding(MRSpacing.lg).background(MRColor.accentSoft, in: RoundedRectangle(cornerRadius: 18))
            }.relocationPage()
        }.navigationTitle("Education & Work").navigationBarTitleDisplayMode(.inline)
    }
}
