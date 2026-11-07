# Remorrow engineering audit — 7 November 2026

## Scope inspected
SwiftUI ContentView/ReviewView/WelcomeGuideView, Vision OCR, LocalRulesEngine, SmartTitleGenerator, SwiftData, EventKit, return alarms, Share Extension, selected-text Action Extension, App Group inbox, XcodeGen targets, and automated unit tests. Audited the source and GitHub Action checks. No physical device or private user messages were accessible.

## Implemented and source-reviewed
- [x] Offline local extraction and evidence-based suggestions only
- [x] Deterministic relative weekday/date parsing with explicit time uncertainty
- [x] Separate multiple dated intents with OCR line splitting and guarded joining
- [x] Do not combine text across visible OCR bubble/paragraph gaps
- [x] Ignore common screenshot chrome (isolated timestamps, Read, Messages, Today)
- [x] Mark tentative plans as unconfirmed; never write Calendar/Reminders during parsing
- [x] Per-proposal review, progress indicator and Skip
- [x] Photo picker triggers analysis; live camera exists with device availability check
- [x] First-launch visual guide (3 pages), Skip, persistent completion flag, Settings replay
- [x] Atomic app-group shared content manifest; chronological import
- [x] Real saved-plan details and source-image attachment
- [x] Documentation and project assets tracked in GitHub

## Known limitations — do NOT call production-perfect
- Language understanding remains conservative **rules, not a trained language model**. Indirect promises, implicit dates, speaker attribution, sarcasm, crossed-out text, multilingual chats, and conversational dependencies can be missed or misinterpreted.
- OCR line spacing is only a heuristic for chat bubble boundaries. Different iPhone display settings and chat apps can break grouping. Review is mandatory.
- Dates with unknown hours use an editable placeholder with warnings. Ambiguous phrases such as "next Friday" require explicit human verification.
- OCR currently uses Vision's best text candidate and does not expose per-token confidence to the user.
- EventKit event duration is currently one hour by default; editing linked external events and full reconciliation are unfinished.
- App Group handoff, action extension visibility, EventKit authorization and camera require real signed-device testing.
- No end-to-end XCUITest coverage yet; UI accessibility, Dynamic Type, VoiceOver, permission denial/revocation and photos/attachments need a device matrix.
- Potential double-saving through interruption/retry during external EventKit writes needs an idempotency/recovery mechanism.
- There is no production Apple Foundation Models integration yet; availability and benchmarks are still research work.

## Release gates
1. GitHub simulator **build + unit tests must pass on the final commit**.
2. Real iPhone: first launch and skip, screenshot multi-action, original image in details, review/skip/save, protected photo permissions and real Calendar/Reminders verification.
3. Test Notes/Safari selected text and Photos share independently; Messages cannot be read automatically.
4. Verify no network uploads, app group and delete behavior, privacy statements and file lifecycle.
5. Validate OCR false-positive rate, date timezone/DST semantics, and no unapproved writes with fabricated test screenshots.

## Next engineering work
1. Conditional Apple on-device language model on eligible iPhones plus conservative offline rules fallback; test structured extraction against >150 synthetic conversations.
2. Idempotent writes and external-item reconciliation; avoid duplicates after crash.
3. Robust chat-speaker layout analysis, OCR confidence warnings and explicit source attribution.
4. UI test target, real-device accessibility/performance and App Store checklist sign-off.

**Disposition:** usable test build for product validation after successful CI, not App Store ready.
