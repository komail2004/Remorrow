# Financial capture and paid-release hardening — 2026-11-22

Status: **Draft PR; not certified for App Store release**.

## Source-based findings
- FinancialDocumentParser previously assumed the first plausible OCR line was the merchant, and the next line was the item; receipt metadata, transaction IDs and totals can be misread as products.
- A subscription was named by appending "subscription" to an inferred merchant.
- SubscriptionItem stored an amount and broad frequency but no numeric recurrence interval or currency.
- Subscriptions could edit only name/merchant/next charge, not amount or frequency. Receipt amount also could not be edited after save.
- Monthly spend was formatted as USD even if the underlying amount came from another currency.
- Reminder scheduling covers the next verified charge, not every projected future charge.

## Changes in this branch
- Prioritize explicit item/service/plan labels and exclude receipt headers and obvious metadata when proposing a name; show up to four candidate names so the user can select a different OCR line.
- Prefer total paid / grand total over subtotal, item price or tax.
- Keep all detected details editable. The app must never claim that a guessed item name was verified.
- Add optional persisted interval and currency properties. Legacy records use interval 1 and USD as fallback; migration still needs a physical-device upgrade test.
- Support daily, weekly, monthly, yearly and unknown recurrence; for known frequencies, allow every 1–365 units with projections from the verified anchor date. Unknown frequencies have no speculative forecast.
- Edit saved subscription amounts, currencies, cycles, and next-charge dates; edit a saved receipt's total amount. Updating the saved next charge reschedules its existing notification.
- Show currency-specific monthly estimates. Never add unlike currencies together.
- Add OCR, forecast, and persistence regression tests.

## Important limitations
- OCR is heuristic. In multi-item receipts the correct item cannot always be determined; the user must confirm. No merchant policy or return deadline is inferred from an ordinary purchase date.
- Amounts are self-entered/recognized estimates, not bank transactions or tax accounting.
- The app schedules a notification for the **next verified** charge only. Further dates are *projections*, not confirmed renewals or auto-charged transactions.
- A custom interval is supported for an existing time unit; fully arbitrary irregular billing patterns are not modeled.
- On-device OCR alone cannot guarantee correct branding, especially with cropped, handwritten, multilingual, or low-contrast documents.
- New optional SwiftData properties still need migration testing from a real pre-change TestFlight installation; in-memory tests do not verify schema migration.

## Required acceptance scenarios
1. Scan a receipt beginning with RECEIPT, then merchant, line items and total. Item name must not be the receipt label or grand total.
2. Scan multi-item receipts and ensure alternate choices and manual renaming are available.
3. Enter an explicit product/service name in OCR; it must outrank a generic merchant.
4. Add subscription priced 12.50 USD every 3 months. Save, reopen, edit to 14.99 EUR every 2 weeks, save, reopen, kill/relaunch and verify all fields persist.
5. Inspect projected dates for Jan 31 monthly, every 3 months, leap-year Feb and DST boundaries. Do not drift from original anchor.
6. Mixed EUR/USD subscriptions must display separate monthly estimates.
7. Empty amount remains optional; invalid amount and 2-letter currency are rejected.
8. Unknown billing cadence must not claim future confirmed dates.
9. Confirm next-charge edits replace pending notifications and cancel when subscription is paused or deleted.
10. Upgrade from the current public/TestFlight beta without deleting data; validate SwiftData migration and attachment continuity.
11. Verify VoiceOver, large type, dark mode, iPhone sizes, camera denied, Photos denied, offline mode.
12. Run simulator tests, unsigned Release compilation and signed Release Archive on physical iPhone with all extensions.
13. Check crash logs and actual review behavior. No P0/P1 defects accepted for paid release.

## Full paid App Store release gate
- Real-device source-to-save tests for reminders, date/time parsing, duplicate prevention, Resolve conflict logic, share/text extensions, camera, widgets and notification permissions.
- Apple Developer account agreements, privacy policy/support URLs, accurate App Privacy answers, accessibility and actual screenshots.
- Actual $4.99 *upfront app price* configured in App Store Connect; StoreKit purchase UI is not required solely for an upfront paid app.
- Compliance, code signing, bundle versions, App Groups, export controls and TestFlight test group reviewed.
- No release until these are verified.