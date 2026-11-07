# ADR-0002: Explicit approval before actions
**Status:** Accepted for MVP
## Context
A parsing mistake could create calendar entries at incorrect times or false return deadlines.
## Decision
Every candidate is editable; only explicit user confirmation can write a Calendar event, system Reminder or local return deadline. No automatic commits from a Share Extension.
## Consequences
Slightly more friction, but control, trust and testability. Measure share-to-confirmation time.
