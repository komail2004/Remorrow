# Remorrow — Nine-feature acceptance and engineering review (November 9, 2026)

## Scope
1. **Receipts and warranty intelligence**: on-device Vision OCR, explicit return/warranty date recognition, order number, purchase date/total, saved original photo and OCR, local notifications when permitted. No retailer policy is extrapolated from a purchase date. Source is always user-selected.
2. **Search your memory**: private text search across reminders, original content, receipts, order numbers, warranty/return text, subscriptions; natural question filler handling and month/week filtering. This is keyword-based; embeddings/semantic ranking have not yet been verified.
3. **Existing-plan updates**: local match detection for explicit reschedules, with an independent **Update existing plan** choice. Never silently overwrites Calendar/Reminders.
4. **Conversation Intelligence**: first-person undated commitments, multi-task dates, reschedule destination date recognition, and capability-gated Apple Foundation Models classification. Guarded model outputs quote an exact excerpt from the user's source, reusing locally parsed dates. Falls back to offline rules.
5. **Daily briefing**: prioritized overdue / today / soon items, with optional generic morning notification and no titles on locked-screen alerts.
6. **Subscription forecasting**: calendar-based projections and approximate monthly-equivalent spending, clearly distinct from real transactions.
7. **Smart timing**: optional additional EventKit lead-time alarms, default off; contextual alerts for returns and subscriptions.
8. **Shortcuts and Siri**: explicit text passed to an App Intent goes to the existing on-device App Group inbox, not directly to a scheduled event.
9. **Widgets**: privacy-first, blue/navy small and medium WidgetKit Home Screen snapshots of aggregate counts; opt-in for next title. Uses App Group summaries.

## Tests and verification
- Each feature creates a GitHub Actions build on `main`; the same CI simulator suite includes all unit tests.
- Tests cover OCR/extraction fixtures, conversation uncertainty, reschedule matching, warranty-vs-purchase separation, keyword ranking, date filters, briefing calculation, subscription projections, notification timing, Shortcut input validation and SwiftData persistence.
- **Must verify the final main commit's iOS build AND tests both pass**. Passing an earlier commit is insufficient.
- A simulator does not prove physical iPhone camera/OCR, Siri utterance, selected-text action appearance, WidgetKit gallery registration, App Group provisioning, or Apple Foundation Models availability. Test on actual hardware and supported OS.
- AI-generated suggestions and inferred responsibility, dates, retailer policies, transaction charges and external updates require human approval.
- Existing workflows should be regression-tested: first-launch skip, screenshot import, manual reminder, EventKit approvals, saved details, receipt camera/Photos, date edits, returns, subscription pause, original document search, Share and Action extensions.

## Remaining release blockers
- On-device Apple Foundation Models code path must be verified using an iOS 26+ SDK with model enabled on compatible iPhone. CI using an older SDK does not compile that conditional branch.
- App Group, widget, Shortcuts and both share extensions require development-team signing and real-device verification.
- No production-ready automatic recovery if EventKit commits but SwiftData fails, and no complete UI automation suite yet.
- OCR layout segmentation remains heuristic for unusual screenshots; handwriting, multilingual conversations and conflicting message revisions require broader test fixtures.
- Local widget snapshots can be stale until the main app runs, since WidgetKit refresh timing is controlled by iOS.
- Subscription forecasts do not confirm actual billing or cancel services. No remote or bank data is read.

**Status:** Feature implementations under CI verification, not App Store release approval.
