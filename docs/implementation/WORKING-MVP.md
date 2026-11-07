# Working MVP increment — implementation status
## Added
- Returns tab with user-verified deadlines, SwiftData persistence, mark returned/reopen, delete and optional local alert.
- Local notifications for returns (generic lock-screen content, no private item names).
- Apple Reminders receive alarm at due date.
- Saved action long-press deletion removes Apple Calendar/Reminders entry first, then local history; errors do not falsely claim success.

## Still not finished
- Editing saved system actions, sophisticated multiple-action parsing, Apple Foundation Models integration, iOS Share Extension, return receipt import/auto-extraction, background reconciliation, real-device sign-off.
- There is no guarantee alerts are delivered when iOS permissions or Focus settings prevent them.

## QA
Use CI simulator build/tests and test on physical iPhone. Confirm Add Return, denial of notification permission, mark returned, and deletion. Inspect EventKit deletion with real events; no silent destructive operations.
