# App Store Release Checklist
- [ ] Brand/trademark clearance for Remorrow completed.
- [ ] Bundle IDs, signing, entitlements, deployment target and test device matrix finalized.
- [ ] Functional in-app privacy policy and support URL.
- [ ] Apple permission purpose strings accurately match use.
- [ ] No unauthorized access to SMS/email or other apps.
- [ ] No incorrect claims of guaranteed parsing, return dates or notification delivery.
- [ ] Review flow prevents accidental external Calendar/Reminders changes.
- [ ] Screenshots and preview footage reflect real shipping features.
- [ ] Accurate App Store privacy nutrition labels, content rating and pricing configured.
- [ ] VoiceOver, reduced motion, large text and dark mode QA.
- [ ] TestFlight distribution and crash/error triage complete.
- [ ] Store review notes describe Share Extension and permissions.
- [ ] App Review guidelines checked against current versions before submission.

## November 2026 launch QA
- [x] Custom time option and EventKit validation added to Resolve
- [x] Privacy manifest source files added for app and extensions
- [x] In-app privacy summary and publicly hostable privacy-policy draft written
- [x] External-write/local-store compensating failure handling updated
- [ ] Latest main: simulator build and complete unit/UI suite both pass
- [ ] Production Release Archive signed with all four bundle IDs and App Group
- [ ] Actual iPhone tests for OCR, camera, Calendar, reminders, Shortcuts, extensions, widgets, and notifications
- [ ] Public privacy/support URLs and real contact details provided
- [ ] Accessibility, low-storage, offline, migration, DST, and timezone QA
- [ ] TestFlight with real beta testers and crash/bug triage
- [ ] Name clearance and $4.99 paid upfront price configured in App Store Connect
- [ ] Current Apple policy, privacy reason APIs and App Store listing checked
- [ ] Owner approves release gates G0–G5; no unresolved P0/P1 bugs

See [full launch audit](LAUNCH-READINESS-NOV-2026.md).
