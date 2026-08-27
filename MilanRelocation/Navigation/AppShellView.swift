import SwiftUI

struct AppShellView: View {
    @State private var selection: AppDestination? = .today

    var body: some View {
        NavigationSplitView {
            List(AppDestination.allCases, selection: $selection) { destination in
                Label(destination.title, systemImage: destination.icon)
                    .tag(destination)
                    .accessibilityIdentifier("nav-\(destination.rawValue)")
            }
            .navigationTitle("Milan")
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill").foregroundStyle(MRColor.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Henry & Jeff").font(.caption.weight(.semibold))
                        Text("Private workspace").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.thinMaterial)
            }
        } detail: {
            Group {
                switch selection ?? .today {
                case .today: TodayView()
                case .tasks: TasksView()
                case .timeline: TimelineView()
                case .budget: BudgetView()
                case .housing: HousingView()
                case .educationWork: EducationWorkView()
                case .documents: DocumentsView()
                case .contacts: ContactsView()
                case .weeklyReview: WeeklyReviewView()
                case .settings: SettingsView()
                }
            }
            .accessibilityIdentifier("screen-\((selection ?? .today).rawValue)")
            .background(MRColor.background.ignoresSafeArea())
        }
        .navigationSplitViewStyle(.balanced)
    }
}
