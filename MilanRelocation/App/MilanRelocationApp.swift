import SwiftUI

@main
struct MilanRelocationApp: App {
    @State private var store = MockRelocationStore()
    @State private var taskStore = TaskStore.live()
    @State private var budgetStore = BudgetStore.live()
    @State private var housingStore = HousingStore.live()
    @State private var notificationService = NotificationService.live()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(store)
                .environment(taskStore)
                .environment(budgetStore)
                .environment(housingStore)
                .environment(notificationService)
                .tint(MRColor.accent)
                .preferredColorScheme(.light)
        }
    }
}
