import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @Environment(NotificationService.self) private var notificationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                permissionSection

                Section {
                    Picker("Reminder timing", selection: timingBinding) {
                        ForEach(ReminderTiming.allCases) { timing in
                            Text(timing.title).tag(timing)
                        }
                    }
                    .accessibilityIdentifier("notification-reminder-timing")
                } header: {
                    Text("Timing")
                } footer: {
                    Text("Applies to task due dates, housing follow-ups, and document expirations. Overdue reminders use the next 9:00 AM slot.")
                }

                Section {
                    ForEach(NotificationCategory.allCases) { category in
                        Toggle(isOn: categoryBinding(category)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(category.title)
                                Text(category.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("notification-category-\(category.rawValue)")
                    }
                } header: {
                    Text("Reminder categories")
                } footer: {
                    Text("Daily summaries arrive at 8:00 AM. Weekly reviews arrive Mondays at 6:00 PM.")
                }

                if let error = notificationService.lastErrorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(MRColor.red)
                            .accessibilityIdentifier("notification-error")
                    }
                }

                Section("Privacy") {
                    Label("Reminders stay on this device", systemImage: "iphone.and.arrow.forward")
                    Text("No push notification provider, backend, account, or external identifier is used.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(MRColor.background)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("notification-settings-done")
                }
            }
            .task { await notificationService.refreshPermissionStatus() }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder private var permissionSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: permissionSymbol)
                    .font(.title2)
                    .foregroundStyle(permissionColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Permission").font(.subheadline.weight(.semibold))
                    Text(notificationService.permissionStatus.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if notificationService.permissionStatus.canSchedule {
                    Text("\(notificationService.scheduledCount) scheduled")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MRColor.accent)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Notification permission, \(notificationService.permissionStatus.rawValue)")
            .accessibilityIdentifier("notification-permission-status")

            if notificationService.permissionStatus == .notDetermined {
                Button("Allow notifications") {
                    Task { await notificationService.requestPermission() }
                }
                .accessibilityIdentifier("notification-request-permission")
            } else if notificationService.permissionStatus == .denied {
                Text("Notifications are denied. Reminders remain disabled until permission is changed in iOS Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open System Settings") {
                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
                .accessibilityIdentifier("notification-open-system-settings")
            }
        } header: {
            Text("Permission status")
        }
    }

    private var timingBinding: Binding<ReminderTiming> {
        Binding(
            get: { notificationService.preferences.reminderTiming },
            set: { notificationService.setReminderTiming($0) }
        )
    }

    private func categoryBinding(_ category: NotificationCategory) -> Binding<Bool> {
        Binding(
            get: { notificationService.preferences.isEnabled(category) },
            set: { notificationService.setEnabled($0, for: category) }
        )
    }

    private var permissionSymbol: String {
        switch notificationService.permissionStatus {
        case .authorized, .provisional, .ephemeral: "bell.badge.fill"
        case .denied: "bell.slash.fill"
        case .notDetermined: "bell.badge"
        }
    }

    private var permissionColor: Color {
        switch notificationService.permissionStatus {
        case .authorized, .provisional, .ephemeral: MRColor.success
        case .denied: MRColor.red
        case .notDetermined: MRColor.amber
        }
    }
}
