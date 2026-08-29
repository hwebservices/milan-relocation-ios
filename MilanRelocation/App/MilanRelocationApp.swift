import SwiftUI

@main
struct MilanRelocationApp: App {
    @State private var taskStore = TaskStore.live()
    @State private var budgetStore = BudgetStore.live()
    @State private var housingStore = HousingStore.live()
    @State private var documentStore = DocumentStore.live()
    @State private var notificationService = NotificationService.live()
    @State private var contactStore = ContactStore.live()
    @State private var weeklyReviewStore = WeeklyReviewStore.live()

    init() {
        if ProcessInfo.processInfo.environment["MILAN_RESET_SETTINGS"] == "1" {
            UserDefaults.standard.set(true, forKey: "showCompletedTasks")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(taskStore)
                .environment(budgetStore)
                .environment(housingStore)
                .environment(documentStore)
                .environment(notificationService)
                .environment(contactStore)
                .environment(weeklyReviewStore)
                .tint(MRColor.accent)
                .preferredColorScheme(.light)
        }
    }
}
