# Semantic duplicate and schedule-conflict protection

## Behavior
Remorrow previously recognized only explicitly worded reschedules. It could create duplicate Calendar events when the same plan had different conversational wording. The new on-device matcher compares activities and meaningful subjects, not just literal titles.

- "Dinner with Rubi" and "Rubi will have dinner with me" on the same date and time: likely duplicate
- Same two descriptions on the same day at noon versus 8 PM: possibly the same plan with a changed time
- Dinner with Rubi versus Dinner with Alex at 8 PM: time overlap, not a duplicate
- Independent reminders due together: no generic conflict warning
- A recurring dinner a week later: not automatically a duplicate

## User choices
The Review screen checks all Remorrow-saved plans using the edited title, type and date, warns before creating a likely duplicate or overlap, and can offer Update existing plan. Choosing to save separately requires another confirmation; no action is changed without approval.

My Plans now offers Review possible duplicates for saved records. Keep both remembers the decision. Remove extra copy asks for confirmation and uses the existing Apple Calendar/Reminders-aware deletion process. Nothing is merged or deleted silently.

Smart titles now prefer the actionable sentence instead of greetings and recognize an explicit statement like "Rubi will have dinner with me" as "Dinner with Rubi." Absolute date extraction favors stated times, including 8 PM.

## Boundaries
This is a conservative local matcher against plans previously saved by Remorrow, NOT an exhaustive scan of every event in Calendar. Wording variations, nicknames, multilingual messages and true reschedules may still require manual review. Separate events are allowed to overlap if the user confirms. Saving an update uses the actual linked Apple identifier.

## Acceptance checklist
1. Save "Dinner with Rubi" for November 20 at 8 PM; capturing "Rubi will have dinner with me" for that time must warn about a likely duplicate.
2. Repeat for noon versus 8 PM; offer a possible change/update rather than silently merging.
3. Schedule Dinner with Alex at the same time; warn of overlap rather than naming it a duplicate; allow keeping both.
4. Different reminders at the same time must be allowed.
5. A weekly repeat must not be classified as identical.
6. My Plans must display existing possible duplicates; Keep Both persists and removing one asks before deleting its linked Apple item.
7. Editing title/time/kind in Review must recompute the warning; the save handler checks again before an external write.
8. Verify explicit 8 PM and missing time behavior; run simulator tests and physical device checks.
