# Product Analytics and Validation
**Principle:** Validate paid utility value without surveilling user messages.

## North-star
**Successfully confirmed useful actions per active customer**, measured only if privacy-safe instrumentation is intentionally implemented and disclosed. In the MVP, use opt-in usability studies / local developer diagnostics rather than hidden telemetry.

## Funnel
Open -> Capture initiated -> Content entered/shared -> Proposal shown -> Edited/confirmed -> External save succeeded. Track failures, not user content.

## Quality metrics
- Correct-event precision under human review, with ambiguity and abstention measured separately.
- OCR accuracy by synthetic screenshot type.
- Candidate correction rate, false date rate, missing-event rate.
- Median and p95 capture-to-save time, offline completion, permission-denial recovery.
- Return-date confirmation and scheduled-alert correctness.

## Business tests
- Hypothesis: some US users will pay $4.99 upfront for time saved.
- Competing alternatives: built-in iOS Reminders / Calendar, ChatGPT, free receipt trackers.
- Run interviews and a genuine paid launch experiment; do not interpret click-through as purchase.
- App Store product-page conversion and Apple Ads cost per *paid* acquisition determine scaling.
- Stop paid campaigns if acquisition cost exceeds net receipts after fees/refunds.

## Targets
Targets are to be set from a documented pilot benchmark, not invented. No credible assumption that $20K is easy or guaranteed.
