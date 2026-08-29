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
- **Services** provides protocols and local implementations. `TaskStore` owns editable task state and JSON persistence; `MockRelocationStore` supplies the remaining foundation fixtures.
- **Resources** contains the asset catalog.

## State and data flow

`TaskStore` and `MockRelocationStore` are created once by the app and injected through SwiftUI's environment. Task mutations flow through `TaskStore`, which sorts and atomically saves the collection after each successful create, edit, or delete action. Persistence is isolated behind `TaskPersistence`, so tests use an in-memory implementation and a future shared repository can replace local JSON without restructuring feature views.

The timeline is a projection of `TaskStore` rather than a separate data source. `GanttTimelineLayout` owns date-range, duration, zoom-scale, milestone, and positioning calculations independently from SwiftUI, keeping the chart deterministic and unit-testable.

## Design system

The visual language uses warm ivory surfaces, ink text, deep Milan green as the single action accent, fine dividers, generous spacing, and restrained card use. Status colors communicate meaning but do not compete with primary navigation.

## Future boundaries

Authentication, cross-device synchronization, sharing, and production notifications are intentionally outside this milestone. They should be introduced behind service protocols after privacy, access, and hosting decisions are approved.
