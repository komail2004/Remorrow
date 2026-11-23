# Remorrow — second production-readiness pass (2026-11-23)

**Status: engineering validation in progress; NOT a signed or publicly certified App Store release.**

## Audit baseline and evidence

- Baseline: `main` at `d764f7c4f48c75547e31909916aeffaeed76af79`.
- [GitHub Actions #45098022610](https://github.com/komail2004/Remorrow/actions/runs/45098022610): **135 unit tests and 9 UI tests, zero failures; simulator build, unsigned iPhoneOS Release build, and extension metadata validation all passed**.
- This branch: `release/receipt-return-edit-hardening-2026-11-23`.
- Build number and bundle ID remain `1.0 (2)` and `com.komail2004.remorrow`. Shared App Group remains `group.com.komail.Remorrow`.
- No Apple signing credentials, App Store Connect account session, or physical-device TestFlight installation were available to the code-review environment. Claims of these checks succeeding would be false.

## Findings and fixes

### H1 — Receipt without return deadline could not be completed later (P1)
**Before:** Creating an untracked receipt saved `hasConfirmedReturnDeadline=false`. The editing sheet exposed a date field but no tracking switch, so users could not enable a return reminder after learning the store policy.

**Fix:** Saved receipts may now enable/disable confirmed return tracking and edit purchase date, order number, warranty expiry, item name, merchant, amount, and currency. New/changed return and warranty dates require explicit verification. The updated model is saved before local notifications are rescheduled or dismissed.

### H2 — Receipt capture assumed a return date without evidence (P1)
**Before:** `trackReturn` started true even with no recognized return policy. The screen displayed a suggested placeholder deadline and required verification, creating a risk of a false assumption.

**Fix:** Return tracking starts disabled. It is suggested only when a recognized, future return deadline exists; users can opt in manually. The deadline picker is hidden when return tracking is disabled. Removing a scan clears its prior OCR-derived fields and tracking switches rather than retaining a stale name, amount, or assumed date.

### H3 — Failed database save could leave orphaned pending models (P1)
**Before:** A failed receipt/subscription insert removed its saved photo but did not roll back the unsaved SwiftData insertion. A later save could persist a record referencing the deleted image.

**Fix:** Roll back `modelContext` before attachment cleanup after a failed insert.

### H4 — Importing large shared payloads could consume unbounded memory/storage (P2)
**Before:** Share extension accepted arbitrarily large text/images, and SharedInbox decoded unbounded JSON manifests. A manifest failure could orphan an image.

**Fix:** Share extension now limits text to 20,000 characters and image data to 30 MiB. Selected-text extension enforces the same text limit. Inbox reads up to 256 KiB per manifest before decoding and still processes valid queued shares. Staged images are cleaned up if manifest writing fails.

## Automated acceptance

- Existing tests cover receipt OCR numeric formats, AI grounded names, custom subscription cadence/currency, calendar conflict detection, DST and schedule reschedules.
- Added regression coverage for persisting a receipt's newly confirmed return deadline, amount, currency, warranty and receipt number; for default receipt capture without a return deadline; and for skipping oversized shared JSON manifests.
- New branch Xcode tests and unsigned release metadata: **PENDING**. Record CI run and exact total before merging.
- No test here creates actual Apple Calendar events, confirms local notification delivery, validates a SwiftData migration from the shipping beta, or verifies Foundation Models inference on an eligible device.

## Manual device sign-off: mandatory

1. **Bundle ID:** inspect the *existing* App Store Connect app record and installed Build 1. Its main bundle ID must match `com.komail2004.remorrow`; verify all extension IDs and the App Group entitlement. Repo settings alone do not prove the installed binary uses those IDs.
2. **Non-destructive migration:** keep Build 1 installed and use expendable sample records. Install Build 2 over Build 1. Verify reminders, receipts, attachments, subscriptions, defaults, share extensions and widget digest. **Do not uninstall Build 1.**
3. **Receipts:** physically scan at least 20 diverse examples including no return date, multi-item receipts, low light, blurry currency and receipt totals. Save without a return date; reopen; add a confirmed return date and warranty; check the correct notifications.
4. **Commitments:** test 7 PM, a time range, "moved from 6 PM to 7 PM", spring/fall DST, duplicates, updates, declined Calendar permission and conflict resolution using a *test calendar*.
5. **Apple Intelligence:** test an eligible iPhone with the model available and an unsupported/unavailable device in fallback mode; confirm no invented titles and editable suggestions.
6. **Extensions:** share a normal image/text, over-limit image/text, cancel and retry. Confirm no dropped drafts or App Group crashes.
7. **UX:** VoiceOver, Dynamic Type, reduce motion, camera denied, Photos denied, offline, low storage, background/foreground and cold starts.
8. **Distribution:** use the owner's valid Apple Developer team to run `scripts/archive-signed-release.sh`, verify signing and generate an App Store IPA; upload, validate, and test with TestFlight before Apple review.
9. **App Store Connect:** publish accurate privacy policy and accessible support URL, set the upfront US price to $4.99, complete banking/tax, screenshots, category, age rating, content rights, App Privacy, export compliance and App Review metadata.

## Release decision

**NO-GO for public submission** until latest CI passes and steps 1–9 above have evidence. Source changes and passing unsigned CI are meaningful, but do not establish signing, installation compatibility, notification delivery or acceptance by Apple's review team.

Focus next on completing a physical iPhone upgrade test and signed archive. Do not invent results or bypass the Bundle ID guard.
