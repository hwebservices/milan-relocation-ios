import SwiftUI

struct AppShellView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(HousingStore.self) private var housingStore
    @Environment(DocumentStore.self) private var documentStore
    @Environment(NotificationService.self) private var notificationService
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
        .task(id: notificationScheduleSignature) {
            await notificationService.rebuildScheduledNotifications(
                tasks: taskStore.tasks,
                housingListings: housingStore.listings,
                documents: documentStore.documents
            )
        }
    }

    private var notificationScheduleSignature: String {
        let tasks = taskStore.tasks.map {
            "\($0.id.uuidString)|\($0.status.rawValue)|\($0.dueDate.timeIntervalSince1970)"
        }.joined(separator: ";")
        let housing = housingStore.listings.map {
            "\($0.id.uuidString)|\($0.qualification.rawValue)|\($0.nextFollowUpDate?.timeIntervalSince1970 ?? -1)"
        }.joined(separator: ";")
        let documents = documentStore.documents.map {
            "\($0.id.uuidString)|\($0.name)|\($0.status.rawValue)|\($0.isArchived)|\($0.expirationDate?.timeIntervalSince1970 ?? -1)"
        }.joined(separator: ";")
        return [
            tasks, housing, documents, notificationService.preferences.scheduleSignature,
            notificationService.permissionStatus.rawValue
        ].joined(separator: "#")
    }
}
