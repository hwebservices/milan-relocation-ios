# Data model

## RelocationTask

The primary unit of work. A task has a title, category, owner, status, priority, optional start date, due date, optional notes, and a stable identifier. Overdue state is calculated rather than stored: a task is overdue when its due date is before the comparison date and its status is neither complete nor cancelled.

## TaskPriority

Priority is one of Low, Medium, High, or Urgent. It affects the task's visual emphasis and provides a stable sort tie-breaker; it does not change overdue calculations.

Task categories act as timeline workstreams. Tasks with a start date are plotted from their inclusive start through due date; tasks without one remain visible in the timeline's Needs Scheduling section. January 28, 2027 is a fixed planning milestone and is not stored as a mutable task.

## TaskStatus

Supported values:

- Not started
- In progress
- Waiting for response
- Blocked
- Complete
- Cancelled

Terminal statuses are `complete` and `cancelled`.

## TaskOwner

Ownership is intentionally small and explicit: Henry, Jeff, or Both. A later shared system can replace this enum with user identifiers while preserving the UI-facing ownership concept.

## Expense and budget

`Expense` records a description, euro amount, date, category, owner, recurrence, optional notes, and local receipt placeholders. Recurrence is either one-time or monthly. Monthly expenses contribute once per month beginning with their recorded month.

`MonthlyBudgetTarget` stores the editable plan for one of the thirteen supported expense categories. `MonthlyBudgetSummary` derives planned spending, actual spending, remaining budget, variance, and the over-budget state for a selected month.

`RelocationFunding` separately tracks relocation cash, deposits, and the emergency reserve. `ReceiptAttachment` stores local placeholder metadata only; no file upload or external identifier is used.

## DocumentItem and ContactItem

Lightweight models support the initial document and contact screens. They are local fixtures and contain no uploaded files or external identifiers.
