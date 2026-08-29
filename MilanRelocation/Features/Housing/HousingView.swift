import SwiftUI

struct HousingView: View {
    @Environment(MockRelocationStore.self) private var store
    private var tasks: [RelocationTask] { store.tasks.filter { $0.category == "Housing" } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MRSpacing.lg) {
                PageHeader(eyebrow: "Home search", title: "Housing", detail: "Track neighborhoods, viewings, and lease decisions.")
                MetricGrid(columns: 2) {
                    MetricBlock(label: "Shortlist", value: "4", detail: "properties")
                    MetricBlock(label: "Preferred", value: "Porta Romana", detail: "neighborhood", emphasized: true)
                }
                SectionLabel(title: "Housing tasks")
                ForEach(tasks) { TaskRow(task: $0) }
                ContentStateView(kind: .empty, title: "No viewings scheduled", detail: "Property appointments will appear here when added.")
            }.relocationPage()
        }.navigationTitle("Housing").navigationBarTitleDisplayMode(.inline)
    }
}
