import SwiftUI

struct SettingsView: View {
    @State private var showCompleted = true
    @State private var showsNotificationSettings = false
    @Environment(NotificationService.self) private var notificationService

    var body: some View {
        Form {
            Section("Workspace") {
                LabeledContent("Members", value: "Henry & Jeff")
                LabeledContent("Currency", value: "EUR (€)")
                LabeledContent("Data", value: "Local on-device")
            }
            Section("Preferences") {
                Button {
                    showsNotificationSettings = true
                } label: {
                    HStack {
                        Label("Notifications", systemImage: "bell.badge")
                        Spacer()
                        Text(notificationService.permissionStatus.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("settings-notifications")
                Toggle("Show completed tasks", isOn: $showCompleted)
            }
            Section("Privacy") {
                Label("No account or cloud connection", systemImage: "lock.shield")
                Text("This app does not upload documents, sync personal data, or use push notifications. Optional reminders are scheduled locally on this device.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(MRColor.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsNotificationSettings) {
            NotificationSettingsView()
        }
        .task { await notificationService.refreshPermissionStatus() }
    }
}
