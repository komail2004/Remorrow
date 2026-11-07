# Software Requirements Specification — Remorrow
**Version:** 0.1 | **Status:** Draft | **Date:** 2026-11-06 | IEEE 29148-inspired, not a certification claim

## 1. Purpose and scope
Specify verifiable behavior of a native iPhone product that accepts user-chosen content and transforms it into proposed reminders, calendar events and shopping-return alerts. Nothing is saved to an external calendar until the user explicitly approves.

## 2. System context and operating environment
SwiftUI iPhone app + Share Extension. Apple Vision performs screenshot OCR; on-device parsing extracts candidate task, event and date information. SwiftData stores local captures/actions. EventKit creates Calendar events and Reminders with appropriate authorization. UserNotifications schedules optional local notifications. PhotosPicker limits image access to chosen content. Exact deployment target to be selected in Sprint 0.

### 2.1 Constraints
An iOS app cannot continuously read SMS/email or other app contents. Share Sheet inputs vary across applications. Time/memory in extension is constrained. Notifications may be delayed, suppressed or denied. Retailer return deadlines vary by product, merchant and delivery date. Pricing set in App Store Connect is not validated by these requirements.

## 3. Stakeholders and users
End users, developer/product owner, QA testers, Apple platform and App Review. Consumers should not need to understand NLP or permissions.

## 4. External interfaces
- **Capture:** typed text, user-initiated paste, PhotosPicker and supported Share Extension UTTypes.
- **Review:** visible source evidence, candidate title/type/date/time/timezone, confidence/ambiguity indicators and edit actions.
- **Commit:** explicit user confirmation to write system event/reminder or local return item.
- **Permissions:** request only contextually; explain denied/revoked states without losing draft.
- **Notifications:** user-approved local alerts with idempotent update/cancel behavior.

## 5. Detailed functional requirements
The FR-001 through FR-022 register in `REQUIREMENTS.md` is normative. Core behavior:

**SRS-01 Capture:** Given text or a supported user-chosen image, create an editable local draft. If OCR cannot extract text, offer manual entry. Never silently inspect unrelated content.

**SRS-02 Extraction:** Preserve evidence text where feasible, separate extracted information from inferences. Missing year, conflicting dates, ambiguous number formats, relative expressions and absent timezones require clarification rather than guessed certainty.

**SRS-03 Review:** Present candidate type, title, date/time, time zone, source evidence and destination. Dismissing the review MUST NOT modify Calendar, Reminders or scheduled alerts.

**SRS-04 Calendar:** Upon permission and confirmation, create exactly one event with approved start/end/timezone. Persist external event identifier after successful write. Retry must avoid duplicates and show recoverable errors.

**SRS-05 Reminder:** Upon permission and confirmation, create one system reminder with approved title/due date. Missing due date is clearly indicated. Denial retains draft.

**SRS-06 Shopping return:** Store merchant, item, optional price/receipt and confirmed return expiry. A receipt without a policy/date MUST require the user to enter or verify expiry before alerts are scheduled.

**SRS-07 Notifications:** On opt-in, queue allowed local notifications and update/cancel them after date changes or deletion. Explain user-controlled iOS notification settings and non-guaranteed delivery.

**SRS-08 Dashboard:** Display saved items by due date, clearly distinguish overdue/completed/scheduled, support edit/delete and clarify effects on linked external events.

**SRS-09 Privacy:** No backend user-content transfer in MVP. Store only necessary input, apply file protection, provide deletion and retention controls, and avoid analytics containing private text/images.

**SRS-10 Error handling:** Recover gracefully from unsupported share types, corrupt images, OCR timeouts, EventKit failures, denial/revocation, duplicate submissions and extension process termination.

## 6. Logical data model
`Capture(id, sourceType, rawText?, imageRef?, createdAt)`
`ActionCandidate(id, captureId, kind, title, startAt?, endAt?, dueAt?, timezone?, evidence, uncertaintyFlags)`
`ConfirmedAction(id, candidateId?, kind, status, externalIdentifier?, confirmedAt, editedAt)`
`ReturnItem(id, merchant?, itemName, amount?, currency?, purchaseDate?, confirmedDeadline, alertOffsets, receiptRef?)`
No real receipt samples or personal messages committed to Git.

## 7. Non-functional requirements
NFR-001–010 in Requirements Register are normative. Validate offline mode, performance, platform version support, VoiceOver/Dynamic Type and privacy claims by test, not assumption.

## 8. Edge cases
"next Friday" near midnight; ambiguous 04/05; year rollovers; DST nonexistent/duplicate hours; all-day events; calendar changes; multiple dates in one image; images with background text; repeated shares; temporary files after extension crash; revoked permission; notification limit; already-past return dates; missing receipts.

## 9. Acceptance, validation and traceability
Each FR/NFR maps to GitHub issue(s) RM-### and TC-### cases. Release requires all P0 acceptance tests, human QA on devices, privacy disclosure review, TestFlight and App Store checklist. New features are not Done without updated requirements and tests.

## 10. Intelligence and interaction amendment
**SRS-AI-01:** Extract text from explicitly selected images locally using Vision OCR; allow review/correction of the text.

**SRS-AI-02:** The intelligence layer returns zero or more typed *proposals* including action kind, title, candidate date, source evidence, and named uncertainty reasons; it has no authority to create external events.

**SRS-AI-03:** On supported devices, an Apple Foundation Models implementation may be selected *only* after capability/availability tests and output validation. Its API compatibility must be verified against the chosen deployment target before implementation.

**SRS-AI-04:** An offline deterministic rules implementation is available when the model is unsupported/unavailable or extraction fails. Clearly communicate weaker interpretation; never disguise fallback as full semantic understanding.

**SRS-AI-05:** Relative dates must be resolved using the current user-provided/reference clock, locale and timezone, with unresolved ambiguity surfaced. Year, end time, return policy and event location may not be invented.

**SRS-AI-06:** If future cloud inference is added, users must explicitly opt in to sending their selected content; implement a server-side secret/key boundary and an equivalent on-device/manual path.

**SRS-UX-01:** Supported capture modes: type/paste, image picker, and Share Extension for available supported content. Unsupported or unreadable content offers an editable text alternative.

**SRS-UX-02:** Review UI displays each proposal and lets the user correct all fields, choose destination, and cancel; all external writes are initiated by explicit confirmation only.

**SRS-UX-03:** Local-first dashboard separates Upcoming, Returns and Completed; it supports search/filter as a post-MVP enhancement.

**SRS-UX-04:** All required screens support VoiceOver, Dynamic Type, high contrast, error recovery, permission denial and accessible labels.

**SRS-UX-05:** Consent and privacy language must accurately reflect what content is stored or shared; no automatic reading of iMessage, email, screenshots, or other apps.

See `docs/design/` for UI contract, `docs/quality/` for tests, and `docs/architecture/DATA-MODEL.md` for data lifecycle.
