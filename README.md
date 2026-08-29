# Milan Relocation

A private, native SwiftUI workspace for Henry and Jeff to coordinate their move to Milan. Tasks, expenses, budget targets, relocation funds, apartment listings, housing targets, documents, contacts, and follow-ups are editable and stored locally between launches. Optional reminders use Apple's on-device local notifications; there is no backend, push provider, authentication, analytics, or external dependency.

## Requirements

- macOS with Xcode 26 or newer
- iOS 17.0 or newer simulator/device

iOS 17 is the deployment target because it supports modern SwiftUI navigation and observation APIs while retaining practical device coverage. The project is designed to adopt newer platform features progressively rather than requiring the newest OS.

## Build and run

1. Open `MilanRelocation.xcodeproj` in Xcode.
2. Select the `MilanRelocation` scheme.
3. Choose an iOS 17+ simulator.
4. Press **Run** (`⌘R`).

Command-line build:

```sh
xcodebuild -project MilanRelocation.xcodeproj \
  -scheme MilanRelocation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Run tests:

```sh
xcodebuild -project MilanRelocation.xcodeproj \
  -scheme MilanRelocation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## Structure

The app is organized by feature under `MilanRelocation/Features`, with shared models, navigation, services, resources, and design-system primitives kept in focused top-level folders. See [Architecture](docs/architecture.md), [Data model](docs/data-model.md), [Document tracking](docs/documents.md), [Local notifications](docs/notifications.md), and [TestFlight preparation](docs/testflight.md).
