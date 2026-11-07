# Product Requirements Document (PRD)
**Product:** Remorrow | **Version:** 0.1 draft | **Owner:** product | **Updated:** 2026-11-06

## Vision
People screenshot, forward or paste things they intend to remember, but often fail to turn those fragments into actions. Remorrow turns explicitly shared content into useful, editable reminders and calendar items.

## Audience / jobs to be done
- Students: turn an assignment post into a deadline and reminder.
- Hourly workers: turn a shared message about shifts into calendar entries.
- Shoppers: keep receipts and remember return deadlines.
- Everyone: schedule an appointment from a text without manual retyping.

## Core user journey
1. Type/paste text, select an image, or share supported content into Remorrow.
2. App extracts visible text and proposes dated actions with uncertainty flags.
3. User reviews title, date/time, timezone, action type and relevant details.
4. User explicitly confirms; app saves to Remorrow and optionally Apple Calendar/Reminders as authorized.
5. Local alerts or system reminders notify user, subject to platform permissions.

## MVP boundaries
**In:** on-device OCR, plain-text capture, basic English date/time extraction, candidate review, EventKit, upcoming dashboard, return-deadline manual verification, local notifications, privacy settings, failure recovery.
**Out:** reading inbound messages automatically, purchasing/return initiation, merchant policy scraping, guarantees of notification delivery, unlimited natural-language reliability, cloud accounts, subscriptions, background screen observation.

## Success metrics (targets to validate)
- Median share-to-confirmed-action under 20 seconds on a supported test device.
- No unintended Calendar/Reminders write in any cancel test.
- Zero content uploads during offline MVP QA.
- Measure successful extraction, correction rate and abandonment using consent-respecting tests; do not invent accuracy claims.
- Validate willingness to pay $4.99 with real users and acquisition experiments.

## Monetization and positioning
One-time $4.99 paid App Store download is a hypothesis; verify conversion versus competitor pricing. Promise: "Share it. Remember it." Avoid inaccurate "AI does everything automatically" marketing.

## Open questions
Supported minimum iOS version, exact notifications/backup policy, parser design for ambiguous relative dates, extension data lifecycle, source retention length, preferred event calendar, pricing experiment.
