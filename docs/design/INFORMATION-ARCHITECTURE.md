# Information Architecture
## Main navigation
- **Home / Upcoming:** Today, Soon, Later, Overdue, Completed
- **Capture:** Paste/type, choose photo, incoming shared content
- **Returns:** Active, Due soon, Returned/Archived
- **Settings:** Calendar/Reminders destination, notifications, privacy/storage, help, legal

A central capture affordance may replace a tab, subject to usability testing.

## Objects and navigation
Capture -> Draft -> ExtractionResult (0..N proposals) -> Review -> Destination confirmation -> Saved Action -> Details / Edit / Delete.
Returns have distinct merchant, item, verified deadline and alerts.
Source screenshots should not clutter the main list by default.

## App launch states
1. First launch: brief value explanation; create a sample manually without requiring sign-up.
2. Returning: Upcoming list (or empty state); capture always accessible.
3. Share Extension: short preview + "Continue in Remorrow" when system limitations require opening app.
4. No model availability: local rules path with editable suggestions.

## Navigation rules
- Never lose unsaved user text when permissions are denied or navigation is interrupted.
- Make external calendar writes visible and reversible where possible.
- Keep errors local to the affected action; one failed extraction must not hide the original content.
