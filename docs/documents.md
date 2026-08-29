# Document tracking

The Documents area is a private, on-device checklist for records Henry and Jeff need during the Milan relocation. It copies selected files into the app's private container and never uploads them.

## Records

Each document stores a stable identifier, name, owner, category, workflow status, optional issue and expiration dates, the application or process that requires it, notes, source information, and optional attachment metadata. Supported owners are Henry, Jeff, and Both.

Categories are Identity, Education, Nursing, Employment, Residency, Financial, and Other. Statuses are Not started, Requested, Received, Translation needed, Complete, Expired, and Not applicable.

Attachments contain a file name, content type, optional byte count, date added, and private relative path. Files selected through the system importer are copied into Application Support, can be previewed with Quick Look, and are removed when the attachment or owning document is deleted. They deliberately contain no cloud URL or external identifier.

## Derived states

- **Missing** includes active documents in Not started, Requested, or Translation needed.
- **Expiring soon** means an active, applicable document expires between today and 60 calendar days from today, inclusive.
- **Expired** is derived whenever the expiration date is before today. It overrides the stored workflow status in filters and presentation. A document explicitly marked Expired is also treated as expired.
- **Archived** documents remain persisted but are hidden from the active checklist unless Show archived documents is enabled.

Date comparisons use calendar-day boundaries so time-of-day differences do not create false warnings.

## Persistence and privacy

`DocumentStore` owns create, edit, archive, filtering, derived collections, and JSON persistence. Production data is stored in Application Support as `MilanRelocation/documents.json`. UI tests use a separate resettable file.

All document data and copied files remain local to the app sandbox. Settings can include them in an explicitly exported backup. There is no backend, synchronization, authentication, analytics, or attachment upload.

## Expiration reminders

`AppShellView` observes document status, archive state, and expiration dates. Any change asks `NotificationService` to rebuild pending local notifications. An applicable, unarchived document with a current or future expiration date is eligible for the Document expirations reminder category. Archiving, marking Expired or Not applicable, removing the expiration date, or rescheduling it replaces or cancels the old pending request.

Reminder permission and timing remain controlled in Settings → Notifications. Denied permission never blocks document editing.

## Testing

`DocumentStoreTests` covers effective status, missing and expiration calculations, persistence, create/edit/archive behavior, filters, and attachment metadata. `LocalAttachmentServiceTests` covers import, lookup, backup data, restore, and removal. UI tests cover creating, editing, and filtering documents.
