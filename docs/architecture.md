# Architecture

## Goals

The foundation favors clear feature ownership, SwiftUI composition, and an easy migration from local fixtures to a private shared data source later. No backend assumptions are embedded in feature views.

## Layers

- **App** contains the SwiftUI app entry point and root scene.
- **Core** contains shared utilities and date formatting.
- **DesignSystem** contains color, typography, spacing, and reusable view components.
- **Navigation** defines destinations and the adaptive app shell.
- **Models** contains domain models with no UI dependencies beyond presentation labels.
- **Features** contains one folder per primary app area. Each feature owns its screen and may later own view models and feature-specific components.
- **Services** provides protocols and local implementations. `MockRelocationStore` is the only current data source.
- **Resources** contains the asset catalog.

## State and data flow

`MockRelocationStore` is created once by the app and injected through SwiftUI's environment. Feature views read its observable collections. This keeps mock data centralized and makes a future repository-backed store replaceable without restructuring navigation.

## Design system

The visual language uses warm ivory surfaces, ink text, deep Milan green as the single action accent, fine dividers, generous spacing, and restrained card use. Status colors communicate meaning but do not compete with primary navigation.

## Future boundaries

Authentication, synchronization, persistence, sharing, and production notifications are intentionally outside this milestone. They should be introduced behind service protocols after privacy, access, and hosting decisions are approved.

