import SwiftUI

struct SettingsView: View {
    @State private var weeklyReview = true
    @State private var showCompleted = true

    var body: some View {
        Form {
            Section("Workspace") {
                LabeledContent("Members", value: "Henry & Jeff")
                LabeledContent("Currency", value: "EUR (€)")
                LabeledContent("Data", value: "Local mock data")
            }
            Section("Preferences") {
                Toggle("Weekly review prompt", isOn: $weeklyReview)
                Toggle("Show completed tasks", isOn: $showCompleted)
            }
            Section("Privacy") {
                Label("No account or cloud connection", systemImage: "lock.shield")
                Text("This foundation does not upload documents, sync personal data, or schedule production notifications.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MRColor.background)
        .navigationTitle("Settings")
    }
}

