# Remorrow Resolve — ship-quality conflict assistant

## Product promise
**One scheduling clash. One meaningful question. Up to three calendar-checked options. One explicit confirmation.**

The assistant is optional; it should never block somebody from deliberately keeping overlapping commitments. It does not infer personal priorities, change other people's invitations, or pretend calendar availability proves another participant can attend.

## Where to find it

1. **During review:** when a new Calendar event overlaps a distinct Remorrow-saved event, the Review sheet shows **Resolve this conflict**. Duplicate events are handled separately through the existing **Update existing plan** flow.
2. **My Plans:** when two future events saved through Remorrow overlap, a **Resolve schedule clashes** card opens a list. Choose a pair and tap **Find a solution**, or **Keep both** to remember that choice.

## Interaction
1. Remorrow shows the two event titles and times and asks *Which event could move?*
2. User chooses the new or existing event. If either can move, they pick which to explore; if neither can move, a single question asks which is harder to miss.
3. Only after a user chooses to check, EventKit requests calendar permission and enumerates the calendars the user authorized. The app reads real calendar event start/end intervals and filters out occupied times.
4. Candidate times are on 30-minute boundaries between **8 AM and 9 PM**, within approximately eight local calendar days. Each option respects actual duration for a saved event, an assumed one-hour duration for an unsaved proposal, and a conservative 15-minute adjacent-event buffer. Results are diverse and capped at **three**.
5. When the proposed event is not saved, selecting an alternative **changes the editable date in Review only**. The user must still confirm Save, and Calendar availability is freshly checked immediately before writing.
6. When moving a saved event, the app reads its true duration and checks whether the calendar supports changes. It requires a separate confirmation, rechecks permissions/availability, updates the exact linked EventKit event, and then updates its SwiftData record. If the local save fails, the app attempts to restore the original EventKit date and reports uncertainty instead of claiming success.
7. If the event has attendees, is read-only, or is all-day, Remorrow offers a **drafted time proposal** through the iOS share sheet rather than changing the shared commitment.
8. When neither commitment can move, the app asks which is harder to miss and drafts a considerate message. It never claims to know which personal decision is best.

The blue/navy interface mirrors Remorrow's existing visual design, with one question at a time and no multi-page questionnaire.

## Accuracy and privacy
- Conflict detection in My Plans initially checks **Remorrow-saved Calendar events**, not every external Calendar pair. The free-slot suggestion step checks **all EventKit calendars that Remorrow is authorized to read**.
- The app cannot verify whether people, conference rooms, or travel routes are available. Suggestions state this clearly.
- A bare Calendar event's duration is preserved when moved. Newly created events currently have a one-hour duration until a future editable-duration control is built.
- No background SMS/email access, third-party remote AI, or silent event modifications. Generated message text is never sent without user interaction.
- Access-denied, missing-calendar, missing-event, stale-slot and read-only/shared errors must produce clear messages, never invented availability.
- The deterministic free-time engine works offline on iOS 17+; its results are not model-generated facts. Apple Foundation Models remains optional elsewhere in the capture pipeline.

## Test matrix
- **Slot engine:** busy interval, 15-minute buffers, no fabricated available time, variable duration, 30-minute alignment, up to three meaningfully separated options, and fallback when no future slots exist.
- **Permissions:** declined/revoked Calendar access, no event calendars, source calendar removed, EventKit record identifier missing.
- **Existing event safety:** preserved duration, shared attendee event proposal-only, read-only event proposal-only, confirmation dialog before moving, rollback after failed persistence.
- **User choices:** move proposed item vs. saved item, either movable, neither movable, priority undecided, skip and keep-both.
- **Staleness:** external event added between finding a time and saving; revalidation should reject the newly occupied slot without creating a duplicate.
- **UI:** narrow iPhone, large text / VoiceOver, dark mode, rotation, sheet dismissal, accidental double-taps, and My Plans updates after a move.
- **Data:** no SwiftData migration required, no unapproved App Group access, no new network calls.

**Release gate:** successful GitHub Actions simulator build/unit tests on the final commit, plus physical iPhone verification of real Calendar permissions and actual free/busy behavior. A simulator CI green check does not prove a meeting participant's availability or that Apple Calendar invitations were handled correctly.

## Custom date and time — November 9, 2026
The Resolve alternatives screen now includes **Choose my own time**, immediately below the recommended slots. It expands a compact native date-and-time picker; users can choose future evenings, weekends or dates beyond the recommendation search window.

Tapping **Check this time** runs a fresh EventKit free/busy query, accounting for the event's real duration when already saved, a one-hour assumed duration for an unsaved proposal, a 15-minute buffer, and tentative competing commitments. A verified custom slot then uses the same explicit confirmation path as a recommended slot; changes in the picker clear the prior verification. Busy, past and unverified times must not be marked free. Recommended slots remain optional and a chosen manual time is checked again immediately before any Calendar write.

UI smoke test: `--remorrow-ui-resolve` exposes a DEBUG-only fixture to verify that **Choose my own time** and its picker remain available even if no suggested slots load. A real iPhone signed test is required for actual EventKit availability, booking/concurrent changes, and attendee restrictions.
