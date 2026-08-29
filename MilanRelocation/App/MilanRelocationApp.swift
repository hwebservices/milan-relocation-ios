import SwiftUI

@main
struct MilanRelocationApp: App {
    @State private var store = MockRelocationStore()
    @State private var taskStore = TaskStore.live()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(store)
                .environment(taskStore)
                .tint(MRColor.accent)
                .preferredColorScheme(.light)
        }
    }
}
