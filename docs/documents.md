# Document tracking

The Documents area is a private, on-device checklist for records Henry and Jeff need during the Milan relocation. It does not upload or copy document files.

## Records

Each document stores a stable identifier, name, owner, category, workflow status, optional issue and expiration dates, the application or process that requires it, notes, source information, and optional attachment metadata. Supported owners are Henry, Jeff, and Both.

Categories are Identity, Education, Nursing, Employment, Residency, Financial, and Other. Statuses are Not started, Requested, Received, Translation needed, Complete, Expired, and Not applicable.

Attachment placeholders contain a file name, content type, optional byte count, and date added. They deliberately contain no file bytes, security-scoped bookmark, cloud URL, or external identifier.

## Derived states

- **Missing** includes active documents in Not started, Requested, or Translation needed.
- **Expiring soon** means an active, applicable document expires between today and 60 calendar days from today, inclusive.
- **Expired** is derived whenever the expiration date is before today. It overrides the stored workflow status in filters and presentation. A document explicitly marked Expired is also treated as expired.
- **Archived** documents remain persisted but are hidden from the active checklist unless Show archived documents is enabled.

Date comparisons use calendar-day boundaries so time-of-day differences do not create false warnings.

## Persistence and privacy

`DocumentStore` owns create, edit, archive, filtering, derived collections, and JSON persistence. Production data is stored in Application Support as `MilanRelocation/documents.json`. UI tests use a separate resettable file.

All document data remains local to the app sandbox. There is no backend, synchronization, authentication, analytics, or attachment upload.

## Expiration reminders

`AppShellView` observes document status, archive state, and expiration dates. Any change asks `NotificationService` to rebuild pending local notifications. An applicable, unarchived document with a current or future expiration date is eligible for the Document expirations reminder category. Archiving, marking Expired or Not applicable, removing the expiration date, or rescheduling it replaces or cancels the old pending request.

Reminder permission and timing remain controlled in Settings → Notifications. Denied permission never blocks document editing.

## Testing

`DocumentStoreTests` covers effective status, missing and expiration calculations, persistence, create/edit/archive behavior, filters, and attachment metadata. UI tests cover creating, editing, and filtering documents.
