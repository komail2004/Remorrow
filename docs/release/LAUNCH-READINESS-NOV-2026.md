# Remorrow — Launch Readiness Audit
**Snapshot:** November 9, 2026  
**Status: FUNCTIONAL BETA; NOT YET CLEARED FOR A PUBLIC APP STORE RELEASE.**

## Source and CI review
Reviewed the SwiftUI source, XcodeGen app and three extensions, Vision OCR, Apple Foundation Models fallback, explicit time parsing, EventKit, SwiftData, receipts/subscriptions, notifications, App Intents and Shortcuts, widgets, privacy/entitlement configuration, unit tests, UI smoke tests and GitHub Actions.

## Improvements completed in this pass
1. Remorrow Resolve now lets users choose a **custom future date and time** in addition to three recommended openings. A manual choice is never marked available until EventKit checks it. Verification is repeated before an approved Calendar write.
2. EventKit + SwiftData persistence failures attempt compensating deletion; irrecoverable mismatches produce a warning rather than a false success. Updating shared/read-only Calendar events is prevented.
3. DEBUG-only Resolve fixture and UI test verify the custom-time chooser without prompting for actual Calendar permission.
4. In-app privacy explanation, source privacy manifests, honest policy draft, dynamic version/build label and README beta status.
5. Shared inbox sorted by payload creation time, with a size limit for incoming images and test coverage.
6. Existing parsing, duplicate detection, scheduling, billing forecasts and on-device capture remain in the app.

## G0 — Build and signed app
**Partially covered:** XcodeGen, simulator build/unit/UI tests via GitHub Actions.  
**Owner still must:** run a successful **Release Archive** with the correct Apple Developer Team; verify app and extension bundle identifiers, provisioning and shared App Group group.com.komail.Remorrow; inspect embedded extension versions and entitlements. A CODE_SIGNING_ALLOWED=NO simulator CI build is not a signed device/archive acceptance test. Final main commit's complete iOS test suite must pass.

## G1 — Functional correctness
**Partially covered:** local parser, OCR, Review, EventKit, SwiftData, finance tracking, notifications and Resolve code and tests.  
**Still required on a physical iPhone:** manual and suggested Resolve time validation, new versus saved events, stale Calendar changes, denial/revocation of access, shared/attendee events, screenshots, camera, Photos, App Group handoff, selected-text Action Extension, Siri Shortcuts, original attachments, deletion and reminders. Test a message saying only 7 PM but no date; Review must retain 7:00 PM and explicitly require date confirmation.

## G2 — Privacy and safety
**Partially covered:** no app-owned network/analytics/advertising client visible in source; selected local data, generic notification text, privacy manifests and in-app explanation.  
**Still required:** publish an actual public privacy-policy URL and support URL, add owner contact, review iOS backup/retention statements, verify the shipping privacy report/required-reason declarations, and complete App Store privacy nutrition questions. Remorrow cannot control how the user's Apple or third-party calendar providers sync events.

## G3 — Quality
**Partially covered:** simulator UI tests, accessibility identifiers, responsive native SwiftUI screens.  
**Still required:** physical device matrix, VoiceOver, Dynamic Type, dark mode, reduced motion, offline/permissions test, timezone and daylight-saving changes, low storage, upgrades and SwiftData migrations. No unresolved P0 or P1 issues should be accepted for public release.

## G4 — TestFlight evidence
**Not verified:** Upload a signed build, run real-user beta sessions, examine crashes and incorrect OCR/date or Calendar changes, then resolve launch blockers.

## G5 — Commercial and Apple approvals
**Not verified:** Remorrow name/trademark/App Store availability, Apple Developer program and App Store Connect listing, real $4.99 upfront pricing, country availability, banking/tax agreements, app rating, actual screenshots, review notes and Apple review acceptance. The app uses a proposed paid upfront model, not a confirmed configured StoreKit purchase.

## High-priority manual scenarios
1. Schedule two events at the same time, open Resolve and choose **Choose my own time**. Verify a non-recommended late-evening time can be checked; an occupied time cannot be labeled free; an available time requires confirmation.
2. Change another Calendar event after loading suggestions, then attempt to save: stale availability must be rejected.
3. Move a saved event and verify its actual duration and ID persist; shared/read-only events should yield a proposal draft instead.
4. Deny calendar access or remove writable calendars; no false free-slot claims should appear.
5. Capture Dinner with Ruby at 7pm without a date: Review shows 7:00 PM and insists on verified day.
6. Force/observe external-write or local-save errors: no silent duplicate or misleading success.
7. Test Photo, camera, screenshot OCR, Share/Action extensions, and Shortcuts on a signed physical device.
8. Test receipt/warranty alerts, subscription forecasts, widget privacy toggle and deletion of original images.

## Known limitations
- Conflict discovery initially compares Remorrow-saved events, while its free/busy check can use all authorized calendars. It **cannot confirm other people's availability or travel time**.
- New Calendar event duration is currently one hour. Recurring event edits and recovery from changes to external EventKit IDs are not fully solved.
- Conversation OCR can misattribute text; multilingual and ambiguous dates need broader benchmarks. On-device Foundation Models may be unavailable, requiring local rule fallback.
- Subscription forecasts are estimates, not banking transactions or cancellation tools.
- Device backups may contain app data. Privacy must be accurately described.
- A failed external+local rollback can require manual recovery; Remorrow warns instead of pretending that the two records are synchronized.

**Disposition:** A substantial beta, but launch is blocked by the unverified G0–G5 steps. The owner must sign off after evidence is collected. No silent App Store submission is claimed.
