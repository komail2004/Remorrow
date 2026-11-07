# Screen-by-Screen UX Specification
**Status:** Wireframe-level behavioral spec, not approved high-fidelity mockups.

## S01 Welcome
Value proposition, 3 sample use cases, optional Get Started button. No mandatory account, no global permissions prompt. Skip onboarding on subsequent launches.

## S02 Home / Upcoming
Grouped list: Overdue, Today, This Week, Later; status labels, source type, time zone where material. Empty state CTA "Add something to remember". Swipe actions must offer accessible equivalent buttons.

## S03 Capture
Text editor with paste; choose photo; explanation of supported share content. Analyze CTA disabled for empty content. Preserve text draft. Never read clipboard without explicit interaction.

## S04 Analyzing
Progress state with cancel. OCR/engine errors display copyable extracted text and manual fallback. Do not imply a remote cloud process.

## S05 Review suggestions (critical)
Cards for event/reminder/return. Editable title, start/due date, timezone, location, destination, alerts; show evidence and amber "Confirm date" state where uncertain. Multiple actions each require explicit approval. No automatic writes on opening.

## S06 Date picker / ambiguity resolution
Show interpreted date with day of week and timezone. Warn for past time and DST ambiguity. Offer manual calendar/time selectors.

## S07 Saved confirmation
Clear confirmation of destination, exact date/time and "View in Calendar" or "View reminder" when available. Failure state must not show success.

## S08 Returns
Merchant, item, optional amount, verified return deadline, countdown, alerts, receipt attachment if retained. Editing and marking returned are explicit; missing policy is highlighted.

## S09 Action details / edit
Source summary, associated external ID/status, date adjustments, completion and deletion. Explain whether changes affect linked external records.

## S10 Settings
Notification statuses, Calendar/Reminders permissions, local storage policy, delete all local records, privacy policy, support and app version. No server-side profile settings in MVP.

## S11 Share Extension
Compact preview of incoming text/image, continue/save draft and failure fallback. Respect extension memory/time constraints and host-app return behavior.

## S12 States and overlays
Network offline (should not block basic capture), model unavailable, no text detected, access denied, malformed date, duplicate candidate, conflict, storage full, notification disabled, corrupted receipt. Each has recoverable action and accessible announcements.

## Design acceptance
Screens must have screenshots/prototypes for regular and large text, light/dark appearance, and their empty, loading, success and error states. Apply design tokens from DESIGN-SYSTEM.md.
