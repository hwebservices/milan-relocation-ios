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
- **Services** provides protocols and local implementations. `TaskStore`, `BudgetStore`, and `HousingStore` own editable state and JSON persistence; `NotificationService` owns local reminder permission, eligibility, and scheduling; `MockRelocationStore` supplies the remaining foundation fixtures.
- **Resources** contains the asset catalog.

## State and data flow

`TaskStore`, `BudgetStore`, `HousingStore`, and `MockRelocationStore` are created once by the app and injected through SwiftUI's environment. Mutations flow through their owning store and atomically save after create, edit, or delete actions. Persistence is isolated behind store-specific protocols, so tests use in-memory implementations and a future shared repository can replace local JSON without restructuring feature views.

`BudgetStore` treats one-time expenses as belonging to their recorded month and monthly expenses as active from their recorded month forward. Monthly summaries, category actuals, remaining budget, and variance are derived rather than persisted.

`HousingStore` persists the apartment shortlist and editable Milan targets. Monthly cost, move-in cash, target qualification, and overdue follow-ups are derived. Rent edits append immutable price-change entries, preserving the listing's local history without duplicating current price state.

`NotificationService` is the only layer that imports `UserNotifications`. `AppShellView` observes relevant data signatures and asks the service to rebuild when tasks, housing follow-ups, document expirations, permission, or preferences change. Rebuilding replaces pending app requests so stale reminders are cancelled deterministically.

The timeline is a projection of `TaskStore` rather than a separate data source. `GanttTimelineLayout` owns date-range, duration, zoom-scale, milestone, and positioning calculations independently from SwiftUI, keeping the chart deterministic and unit-testable.

## Design system

The visual language uses warm ivory surfaces, ink text, deep Milan green as the single action accent, fine dividers, generous spacing, and restrained card use. Status colors communicate meaning but do not compete with primary navigation.

## Future boundaries

Authentication, cross-device synchronization, sharing, and production notifications are intentionally outside this milestone. They should be introduced behind service protocols after privacy, access, and hosting decisions are approved.
