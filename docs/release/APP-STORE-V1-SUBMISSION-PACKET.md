# Remorrow — public App Store v1 submission packet

Status: **candidate copy and release checklist; NOT approval to submit.**
Product: **Remorrow – Smart Planner**
Pricing intention: **USD $4.99 upfront**, NOT a subscription.
Version intended: **1.0 (Build 2)** (verify against the actual signed archive and App Store Connect's build history).

## Proposed App Store fields (subject to final screenshots and verification)

**Subtitle (<= 30 characters):** Smart reminders, less effort

**Promotional text:** Turn text, screenshots, and receipts into useful next steps. Review suggestions, resolve schedule conflicts, and keep renewals in sight.

**Description:**

You shouldn't have to manually turn every conversation, screenshot, and purchase into something you'll remember.

Remorrow helps you capture the things you need to do, review what your iPhone recognized, and stay on top of the details.

- Capture reminders and calendar plans from typed or shared text.
- Choose a screenshot or take a photo, and review suggested dates before saving.
- Catch schedule conflicts and consider alternative times. You stay in control of every change.
- Save receipts with original images, purchase details, return deadlines, and warranty dates.
- Track subscription amounts, billing intervals, and upcoming renewals; review projected dates before relying on them.
- Use Today, your saved plans, and optional widgets for a calmer view of what's next.
- Work with Apple's on-device technologies when supported; the core experience does not require an app-owned AI account.

Remorrow doesn't silently read your messages or mailbox and doesn't automatically move calendar events without approval. OCR suggestions, predicted billing dates, and scheduling recommendations can be incorrect; always verify important dates.

A practical planning companion made to reduce busywork—not create more.

**Search keywords draft:** reminder,planner,calendar,screenshot,receipt,subscription,renewal,return,task,schedule

**Categories to evaluate:** Productivity (primary); Lifestyle (secondary only if appropriate). Confirm category availability in App Store Connect.

## Notes for App Review

- The application doesn't require an account or login.
- On first launch the guide can be skipped.
- Reminders: type "Prepare slides tomorrow at 7pm" and review the proposed date before saving.
- Receipts: choose "Receipts" > "Scan receipt", select a test photo, correct the proposed details, and explicitly verify any return/warranty date.
- Subscriptions: "Receipts" > "Add subscription", enter a service and next charge date, then review/edit its amount, currency, and recurring interval.
- Share/text extensions can be invoked from an app that allows standard iOS sharing; they transfer only user-selected content.
- Calendar/Reminders authorization is requested when relevant; the app should continue to operate in limited mode if denied.
- Apple Foundation Models is used only on eligible devices; deterministic local extraction is the fallback.
- Widgets use generic counts by default, without showing task titles unless the user enables that setting.
- The app requires no in-app purchases for the proposed $4.99 *upfront* model.

Review every bullet against the shipping binary. Do not advertise capabilities not demonstrated on a physical iPhone.

## Actual App Store Connect work still required

- [ ] Verify the permanent **com.komail2004.remorrow** app identifier and the actual signed extension IDs.
- [ ] Verify that Build 2 archives, validates, and uploads; retain Build 1 for upgrade testing.
- [ ] Verify the App Group is the same as the installed beta, to avoid losing shared extension access.
- [ ] Finish owner contact, tax and banking agreements, content rights, age rating, and category.
- [ ] Set the paid app tier corresponding to **$4.99 in the US storefront** and review country-level pricing.
- [ ] Host a publicly accessible privacy policy and support page with a real contact method; verify URLs independently.
- [ ] Complete App Privacy disclosures based on the final binary and the actual connected services.
- [ ] Add genuine App Store screenshots captured from the shipping app in required device sizes.
- [ ] Check rights to all icons, fonts, assets, copied text, and screenshots.
- [ ] Complete encryption/export compliance accurately for the shipping binary.
- [ ] Fill App Review contact details and explain permission-dependent flows.
- [ ] Confirm TestFlight beta approval and tester feedback, then submit *manually* only after QA sign-off.

## Non-negotiable release tests

### Upgrade without losing users' data
1. On a physical iPhone with the existing TestFlight Build 1 installed, save a receipt with an image, a subscription with an amount, and a reminder.
2. Back up/export any irreplaceable data before testing. **Do not delete the installed app.**
3. Install Build 2 over Build 1 through TestFlight, preserving the same main app identifier and App Group.
4. Verify all three records survive, existing attachments open, subscription defaults migrate, editing remains possible, and notification state is appropriate.

### Finance edge cases
- Multi-item receipt, unclear receipt, merchant-only header, poor light, long product name, European price separators, foreign currency, and edited OCR suggestions.
- Subscription weekly, monthly, yearly, daily, every two weeks, every three months, irregular/unknown interval; end-of-month, leap day and DST; overdue next verified date.
- Check that suggested dates are clearly distinguished from verified dates and no unapproved calendar or purchase transaction is invented.
- Confirm editing charge amount/name/frequency/currency without unnecessarily re-verifying an unchanged date.

### General app quality
- Timed commitments (7 PM vs 9:37 bug), duplicate plan detection, edits, deletion, conflict resolution with custom dates, rejected calendar permission, interrupted writes, and notifications.
- Share extension, selected text action, widgets and App Intents on an actual iPhone.
- Offline use, unavailable Apple Intelligence, large text, VoiceOver, dark mode, reduced motion, notification denial, storage pressure and unexpected restarts.
- Full unit and UI test suite, unsigned Release compile, then **signed Release Archive** with actual App Store distribution validation.
- No P0/P1 defects. Owner approval required before public submission.

## Limitations to describe accurately

- Apple Intelligence model availability varies by device, region, language, OS, and settings.
- Screenshot OCR and name ranking are fallible; user can review/edit all extracted fields.
- Future subscription renewal dates are **projections**, not bank-confirmed charges.
- Rolling notification scheduling is subject to iOS limits; no guarantee of an alert when permission is denied or system constraints apply.
- A full Outlook/Microsoft Graph synchronization feature should not be advertised unless actually implemented and verified.
- Real-device migration, signed archive, legal/contact details, App Store metadata and successful human review cannot be established merely by GitHub Actions.

## Release verdict
Until the latest head passes simulator tests, the actual iPhone upgrade is verified, and App Store Connect/privacy/review material is completed: **NO-GO for public App Store submission**.
