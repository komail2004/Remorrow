# Technical Architecture — Remorrow
**Status:** Proposed; implementation is not yet complete.

## Components
1. **SwiftUI iPhone app:** Capture, candidates, confirmation, Upcoming, Returns and Settings.
2. **Share Extension:** Receives supported text/images from user-selected host app; transfers minimal payload to main app using secure App Group storage only after entitlement setup.
3. **Capture layer:** Normalizes pasted/shared text and user-selected images.
4. **OCR layer:** Apple Vision recognizes image text locally.
5. **Extraction engine:** Rule-based date detectors / NSDataDetector with explicit uncertainty analysis; optional on-device models only after evaluation.
6. **Review workflow:** Editable proposal + explicit consent. All writes go through a single commit service.
7. **Integrations:** EventKit calendar/reminder stores; UserNotifications for local alerts.
8. **Persistence:** SwiftData or equivalent local store for drafts, candidates, confirmed actions and return items.

## Data flow
User submission -> normalized capture -> optional OCR -> candidate extraction -> ambiguity and evidence annotation -> editable review -> explicit confirm -> local store and authorized system integration -> success / error feedback.

## Architectural rules
- UI never directly writes system events without confirmed user action.
- Parsing engine is separate from EventKit and persistence, allowing deterministic tests.
- Idempotency keys and external IDs prevent duplicate writes during retries.
- Extension handles bounded workloads; process termination cannot corrupt drafts.
- Do not store images longer than needed by default; document precise retention.
- External event edits/deletion semantics require an explicit ADR before launch.
- Avoid unsupported claims about permission or delivery guarantees.

## Risk and spike register
- EventKit full/write-only permission modes and APIs must be validated against selected iOS deployment target.
- Share Extension delivery, app-group data protection, maximum payload, deep-link behavior and provider compatibility require physical-device tests.
- NLP date extraction on partial text and localization must have explicit abstention rules.
- Notification scheduling limits and behavior on app termination must be tested.

See `docs/architecture/ADR/`, `docs/quality/RISKS.md` and `docs/quality/TEST-PLAN.md`.

## AI backend decision (ADR-0003)
The intelligence layer is provider-independent. Prefer Apple Foundation Models when supported **and** available at runtime. The offline `LocalRulesEngine` remains the baseline for date candidates. User-selected screenshots pass through Apple Vision OCR first. A cloud fallback is an explicitly **future, opt-in** capability; no cloud keys or hidden upload in MVP. All model output is untrusted until validated and reviewed by the user. See `AI-IMPLEMENTATION.md` and `ADR/0003-hybrid-intelligence.md`.
