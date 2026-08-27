# Milan Relocation

A private, native SwiftUI workspace for Henry and Jeff to coordinate their move to Milan. Tasks, expenses, monthly targets, and relocation funds are editable and stored locally as JSON between launches; the remaining feature areas use realistic local fixtures. There is no backend, authentication, analytics, notification delivery, or external dependency.

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

The app is organized by feature under `MilanRelocation/Features`, with shared models, navigation, services, resources, and design-system primitives kept in focused top-level folders. See [Architecture](docs/architecture.md) and [Data model](docs/data-model.md).
