# UX Flows and Acceptance Contracts

## Flow A — Paste a message
1. Tap Capture -> Paste text.
2. Text appears editable. User taps Analyze.
3. Engine returns zero or more candidate actions, with date/uncertainty evidence.
4. Review screen displays title, type, date, timezone, destination, evidence.
5. User changes fields or cancels.
6. Upon confirmation, request needed permissions and save; show success or recoverable error.
**Failures:** Empty text, no detected date, two interpretations, past date, unsupported language.

## Flow B — Share screenshot
1. User selects Share -> Remorrow from a compatible host.
2. Extension receives allowed image data and stores limited handoff safely.
3. Main app reads content; Vision OCR produces editable text.
4. Same review/confirmation as Flow A.
**Failures:** Unsupported provider, giant image, OCR no text, extension termination; allow manual paste/photo select.

## Flow C — Track shopping return
1. Capture receipt/order text or enter manually.
2. Extract merchant/item/possible dates but **never automatically assert a return policy**.
3. Require user to confirm last eligible return date, optionally amount/receipt.
4. Set configurable alert offsets, e.g. 7 and 2 days prior if valid and permitted.
5. Display due soon, mark returned, edit expiry or delete.
**Failures:** Missing date, expired date, no notification permission, date altered.

## Flow D — Change existing event
1. Open saved item -> Edit.
2. Show whether action exists only locally or in Calendar/Reminders.
3. Confirm edit scope; update linked record/alert only after explicit approval.
4. If link is missing, disclose and offer a safe local-only route.

## Flow E — Model unsupported
1. Runtime detection reports no compatible Apple model.
2. Use local rules engine.
3. Show extracted evidence and clearly uncertain fields.
4. Provide manual creation if zero candidates; never block core workflow.

## Flow F — Permission denied
1. Capture/review succeeds regardless of Calendar authorization.
2. Permission prompt occurs only when the user chooses a system destination.
3. On denial, draft is retained, clear guidance is shown; no false success state.

## Metrics
Measure completion rate, share-to-confirm time, correction rate, undo/delete rate, and false-date reports in consented usability testing. Do not send source content into analytics.
