# Today screen — compact overview redesign

## User experience
The old Today view showed a full **Your Daily Briefing** card (three large counters and up to three urgent items) immediately followed by a separate **Your day** card (another date heading and up to five of the same items). This doubled important tasks and consumed most of the iPhone's first screen.

The new Today layout retains the existing cobalt/navy brand header and replaces the two repetitive blocks with **one concise "Your day" card**:

- Subtle date eyebrow and clear 26pt "Your day" title
- One horizontal row of compact overdue, today, and upcoming counts
- Two top-priority items shown by default, with icons and actual dates
- "See N more" to expand the whole agenda in place, and "Show less" to collapse
- A shortcut to My Plans, plus direct detail navigation for saved reminders
- Receipt, warranty and subscription rows continue to route to Receipts
- A calm empty state when nothing is scheduled
- Minimal white card with soft border, consistent blue icons and neutral backgrounds

Briefing data remains available to the widget and notification scheduler; only the redundant standalone **DailyBriefingCard** is removed from Today. This is a presentation change: no EventKit, OCR, SwiftData schema, notification data or persisted reminders are modified.

## Acceptance checks
- One "Your day" section, no second briefing card repeating tasks
- Counts respect overdue/today/soon from confirmed saved plans and receipt/renewal dates
- Two agenda items initially, expand/collapse via the "See N more" control
- Tapping a saved plan opens details; other categories open Receipts
- Small phone, large accessibility text, dark mode, and both empty/busy accounts
- GitHub Actions simulator compilation and UI test to prevent duplicate-heading regression
