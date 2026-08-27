# Data model

## RelocationTask

The primary unit of work. A task has a title, category, owner, status, priority, optional start date, due date, optional notes, and a stable identifier. Overdue state is calculated rather than stored: a task is overdue when its due date is before the comparison date and its status is neither complete nor cancelled.

## TaskPriority

Priority is one of Low, Medium, High, or Urgent. It affects the task's visual emphasis and provides a stable sort tie-breaker; it does not change overdue calculations.

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

## TimelineItem

Represents a dated relocation phase with a start date, end date, category, progress fraction, and owner. Progress is clamped between zero and one by the UI.

## BudgetItem

Represents an expense category with planned and actual amounts in euros. Totals and remaining budget are derived.

## DocumentItem and ContactItem

Lightweight models support the initial document and contact screens. They are local fixtures and contain no uploaded files or external identifiers.
