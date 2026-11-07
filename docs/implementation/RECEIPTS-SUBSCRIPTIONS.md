# Figma-inspired iOS redesign — Receipts & Subscriptions

## Design translation
The supplied Figma travel template is visual inspiration, **not** a copied travel UI: bright-white content surfaces, a saturated cobalt-to-navy masthead, carefully rounded cards, restrained monochrome typography, dark primary actions, two-up featured cards, compact bottom navigation, and prominent image previews. The first-run guide opens on an immersive blue welcome screen; the app retains Remorrow-specific actions and privacy language. No copyrighted mountain photography from the template is bundled.

Implemented in `RemorrowStyle.swift`, `ContentView.swift`, `WelcomeGuideView.swift`, `ReceiptsSubscriptionsView.swift` and `FinancialCaptureView.swift`.

## Receipts
- The Receipts tab opens a two-section hub with Receipts and Subscriptions.
- Tap **Scan receipt** or **Add**. Either choose a Photos screenshot or capture a fresh camera photo on real iPhone.
- Apple Vision extracts OCR locally; `FinancialDocumentParser` proposes merchant, item, amount and an explicit **return-by deadline only when the text actually says so**.
- Name, merchant, and confirmed last return date are editable. Save requires the user to verify the deadline. A purchase date cannot be silently converted into a return deadline.
- Confirmed return records are SwiftData `ReturnItem` with optional image/original OCR attachment in application support. Local notifications are attempted with permission; the app reports when alerts cannot be scheduled.
- Tap an item to see its photo, original OCR, deadline, active/returned state; edit the verified date, mark returned or delete it.

## Subscriptions
- Open **Subscriptions**, tap Add, capture a renewal notice or enter details manually.
- OCR suggests service, amount and a date only when explicitly marked next billing/charge/renewal. An invoice date alone does not count.
- Review name, merchant, next charge date, amount, cadence. Confirm date, save as SwiftData `SubscriptionItem`.
- Date-based generic notification may be scheduled with user permission. No bank integration, email scanning, subscription cancellation, or automatic money movement.
- Subscription records can be viewed, edited, paused/resumed and deleted. The confirmed next renewal is shown on Today.
- Renewal frequency is reference metadata. Future periods are not automatically generated; update the verified next charge each cycle.

## Verification checklist
1. Refresh XcodeGen, run app on iPhone. Test first-launch blue screen, skip, Home capture cards and tab.
2. Test receipt image with purchase date *only*: deadline should remain unverified; save disabled until verified.
3. Test receipt with explicit return-by date: OCR should propose that date; edit and confirm.
4. Test subscription screenshot with next renewal and amount, plus one with only purchase date.
5. Verify saved images and OCR in detail screens, edits, returned/paused states and deletion cleanup.
6. Check notification permission granted/denied and date/time zone behavior.
7. Verify dark mode, small iPhone layouts, large text, Dynamic Type, VoiceOver, and camera fallback in Simulator.
8. Verify no network requests, no automatic Calendar writes, no inferred retailer policy.
9. Run final iOS GitHub Actions build and tests; do not claim real-device UX is fully tested via CI.

## Known follow-up work
- Subscription recurring charge history, expense analytics and repeated notifications are not in this slice.
- Financial OCR has heuristic fields and requires human review; no receipt item-line classification model yet.
- Editing receipt detail currently changes name/merchant/deadline, but amount/frequency editing for subscription needs a further screen.
- A full App Store release requires real iPhone, provisioned extensions and accessibility verification.
