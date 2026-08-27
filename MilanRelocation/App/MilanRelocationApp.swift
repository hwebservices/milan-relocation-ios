import SwiftUI

@main
struct MilanRelocationApp: App {
    @State private var store = MockRelocationStore()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(store)
                .tint(MRColor.accent)
                .preferredColorScheme(.light)
        }
    }
}
