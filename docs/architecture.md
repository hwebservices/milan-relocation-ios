# Architecture

## Goals

The app favors clear feature ownership, SwiftUI composition, and an easy migration from local persistence to a private shared data source later. No backend assumptions are embedded in feature views.

## Layers

- **App** contains the SwiftUI app entry point and root scene.
- **Core** contains shared utilities and date formatting.
- **DesignSystem** contains color, typography, spacing, and reusable view components.
- **Navigation** defines destinations and the adaptive app shell.
- **Models** contains domain models with no UI dependencies beyond presentation labels.
- **Features** contains one folder per primary app area. Each feature owns its screens and feature-specific components.
- **Services** provides protocols and local implementations. `TaskStore`, `BudgetStore`, `HousingStore`, `DocumentStore`, `ContactStore`, and `WeeklyReviewStore` own editable state and JSON persistence. `LocalAttachmentService` owns private file copies, while `NotificationService` owns local reminder permission, eligibility, and scheduling.
- **Resources** contains the asset catalog.

## State and data flow

All stores are created once by the app and injected through SwiftUI's environment. Mutations flow through their owning store and atomically save after create, edit, archive, or delete actions. Persistence is isolated behind store-specific protocols, so tests use in-memory implementations and a future shared repository can replace local JSON without restructuring feature views. Production stores begin empty; sample records are available only to UI tests.

`BudgetStore` treats one-time expenses as belonging to their recorded month and monthly expenses as active from their recorded month forward. Monthly summaries, category actuals, remaining budget, and variance are derived rather than persisted.

`HousingStore` persists the apartment shortlist and editable Milan targets. Monthly cost, move-in cash, target qualification, and overdue follow-ups are derived. Rent edits append immutable price-change entries, preserving the listing's local history without duplicating current price state.

`DocumentStore` persists the document checklist and attachment metadata. `LocalAttachmentService` copies selected receipt and document files into Application Support and resolves them for Quick Look previews. Missing, expiring-soon, expired, and effective workflow states are derived from status and calendar dates. Archiving is reversible and keeps historical records out of active metrics and reminders.

`ContactStore` persists the shared contact directory, and `WeeklyReviewStore` persists dated progress, blocker, and priority check-ins. Education & Work is a live projection of tasks in that workstream rather than a second source of task data. Today derives its counts, countdown, next actions, and focus from current task state.

Settings exports a versioned `RelocationBackup` JSON document containing every store, user preferences, and attachment bytes. Restore requires confirmation and replaces the local workspace with the selected backup.

`NotificationService` is the only layer that imports `UserNotifications`. `AppShellView` observes relevant data signatures and asks the service to rebuild when tasks, housing follow-ups, document expirations, permission, or preferences change. Rebuilding replaces pending app requests so stale reminders are cancelled deterministically.

The timeline is a projection of `TaskStore` rather than a separate data source. `GanttTimelineLayout` owns date-range, duration, zoom-scale, milestone, and positioning calculations independently from SwiftUI, keeping the chart deterministic and unit-testable.

## Design system

The visual language uses warm ivory surfaces, ink text, deep Milan green as the single action accent, fine dividers, generous spacing, and restrained card use. Status colors communicate meaning but do not compete with primary navigation.

## Future boundaries

Authentication, cross-device synchronization, server-side sharing, push notifications, and analytics are intentionally outside this local-first product. They require approved privacy, access, and hosting decisions and should be introduced behind service protocols rather than as incomplete controls.
