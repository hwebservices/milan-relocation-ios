# Local notifications

## Scope

Milan Relocation uses Apple's local notification APIs only. There is no notification backend, push provider, remote device token, account, analytics event, or external identifier.

Notification permission is requested only after Henry or Jeff taps **Allow notifications** in the app's notification settings. If permission is denied, the app shows that state, schedules nothing, and offers a link to the app's page in iOS Settings.

## Reminder categories

- Task due dates
- Overdue tasks
- Housing follow-ups, including overdue follow-ups
- Document expirations
- A recurring daily unresolved-item summary at 8:00 AM
- A recurring weekly relocation review on Monday at 6:00 PM

Each category can be enabled independently. Task due dates, housing follow-ups, and document expirations use the selected lead time: same day, one day before, three days before, or seven days before. Their standard delivery time is 9:00 AM. If the selected lead-time window has already passed, an otherwise eligible reminder uses the next safe local scheduling opportunity instead of being discarded.

## Scheduling lifecycle

`NotificationService` owns permission checks, preferences, eligibility, reminder-date calculations, notification content, system scheduling, and cancellation. Views do not call `UNUserNotificationCenter` directly.

The app observes task, housing, document, permission, and reminder-preference changes. A change rebuilds the pending local schedule from current data. Rebuilding replaces the previous app schedule, so completing, deleting, rejecting, or rescheduling an item removes its stale request automatically.

Notification identifiers are deterministic and namespaced under `milan.*`. iOS limits the number of pending local notifications, so the service reserves two slots for recurring daily and weekly reminders and schedules the earliest 62 dated reminders.

## Eligibility

- Completed and cancelled tasks do not receive task notifications.
- Past incomplete tasks receive an overdue reminder rather than a due-date reminder.
- Rejected housing listings do not receive follow-up reminders.
- Documents must be applicable, unarchived, not explicitly expired, and have a current or future expiration date.
- The daily summary is scheduled only while unresolved tasks, active housing listings, or unresolved active documents exist.

## Testing

Unit tests use an in-memory notification center and preference store. UI tests use a local permission substitute, avoiding Apple's system permission alert and real pending notifications in simulator test runs.
