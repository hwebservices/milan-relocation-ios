import SwiftUI

@main
struct MilanRelocationApp: App {
    @State private var store = MockRelocationStore()
    @State private var taskStore = TaskStore.live()
    @State private var budgetStore = BudgetStore.live()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(store)
                .environment(taskStore)
                .environment(budgetStore)
                .tint(MRColor.accent)
                .preferredColorScheme(.light)
        }
    }
}
