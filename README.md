# Remorrow
**Share it. Remember it.** A privacy-first, native iOS app turning text, screenshots and user-shared content into reviewable calendar events, reminders and shopping-return alerts.

## Product
- Enter or paste text; import a screenshot; receive compatible shared content via the iOS Share Extension.
- Extract candidate events, deadlines and tasks; **always show an editable review** before saving.
- Use EventKit for authorized Calendar/Reminders operations, Vision for OCR, SwiftData for local storage, UserNotifications for alerts.
- Local-first design: no accounts or server-side AI required for MVP.
- Shopping returns: never assume a merchant return date solely from purchase date; user must verify the deadline.
- **Pricing hypothesis:** $4.99 one-time upfront, subject to validation and App Store review.
- Does not automatically read SMS, email or any other app.

## Documents
| Area | Start here |
|---|---|
| Product | [PRD](docs/product/PRD.md) |
| Requirements | [Register](docs/requirements/REQUIREMENTS.md) · [SRS](docs/requirements/SRS.md) |
| Engineering | [Architecture](docs/architecture/ARCHITECTURE.md) · [ADRs](docs/architecture/ADR/) |
| Agile | [Backlog](docs/agile/BACKLOG.md) · [Sprint 0](docs/agile/SPRINT-00.md) · [Roadmap](docs/agile/ROADMAP.md) |
| Quality | [Test plan](docs/quality/TEST-PLAN.md) · [Risk register](docs/quality/RISKS.md) |
| Release | [App Store checklist](docs/release/APP-STORE-CHECKLIST.md) · [Marketing](docs/release/GO-TO-MARKET.md) |

## Status
**Functional iOS beta in active QA (November 2026); not yet cleared for public App Store release.**
This repository includes a generated Xcode project specification, native SwiftUI app, Vision OCR, EventKit review-and-confirm actions, Share and Action extensions, App Intents, WidgetKit, finance tracking, schedule conflict resolution and simulator tests. The latest build status is visible under [GitHub Actions](https://github.com/komail2004/Remorrow/actions). App Store signing, real-device integration tests, public privacy and support links, TestFlight, and legal/commercial review remain release gates. See [current launch audit](docs/release/LAUNCH-READINESS-NOV-2026.md).

## Development
Use GitHub Issues linked to requirement IDs, short-lived feature branches, pull requests and the [Definition of Done](docs/agile/DEFINITION-OF-DONE.md). Never add private user content or secrets to Git.

## Further specifications (November 2026)
- [Hybrid AI implementation](docs/architecture/AI-IMPLEMENTATION.md) · [ADR-0003](docs/architecture/ADR/0003-hybrid-intelligence.md)
- [Design system](docs/design/DESIGN-SYSTEM.md) · [Screen specifications](docs/design/SCREEN-SPECS.md) · [User flows](docs/design/USER-FLOWS.md)
- [Content and accessibility](docs/design/CONTENT-ACCESSIBILITY.md) · [Information architecture](docs/design/INFORMATION-ARCHITECTURE.md)
- [Data model](docs/architecture/DATA-MODEL.md) · [Threat model](docs/quality/THREAT-MODEL.md)
- [Analytics / experiment plan](docs/product/METRICS-EXPERIMENTS.md) · [Launch gates](docs/release/RELEASE-GATES.md)

Intelligence supports deterministic local parsing with optional Apple on-device Foundation Models on eligible iPhones; real iPhone model and permission testing remain necessary.

## Native iPhone UX (November 2026)
- Today: actual due events, reminders and return deadlines, sorted chronologically.
- Capture: typed text, explicit clipboard paste, gallery image and live iPhone camera. Source photo can be kept with a confirmed plan.
- Review: short editable action titles, event/reminder suggestions and explicit confirmation.
- My Plans: tap any saved plan to see its date, Apple destination, original note and attached image.
- Identity: custom dark-ink/gold hourglass app icon and restrained typography.

[UX implementation notes](docs/implementation/UX-POLISH-NOVEMBER-2026.md).

## Receipts & subscriptions — November 2026
The app includes a Figma-reference-inspired blue/white design and a new combined **Receipts** tab. Receipt and subscription screenshots can be selected from Photos or taken live with the iPhone camera. On-device Vision OCR proposes details, and users must explicitly verify the last return date or next subscription charge before records and optional notifications are saved. Source photos and recognized text stay on-device. See [implementation details](docs/implementation/RECEIPTS-SUBSCRIPTIONS.md).

## Nine-feature intelligence expansion (November 2026)
Remorrow now includes verified warranty tracking; local cross-category memory search; suggested reschedule updates; capability-gated on-device Apple Foundation Models with local rules fallback; a daily briefing; projected subscription renewals; opt-in contextual alerts; Siri/Shortcuts text capture; and privacy-first WidgetKit Home Screen widgets. See [implementation, tests and known limitations](docs/quality/NINE-FEATURE-ACCEPTANCE.md). Apple Intelligence and other OS integrations require eligible devices and signed physical-device acceptance tests.

## Semantic duplicate and schedule-conflict checks
When saving a reviewed action, Remorrow now checks its own saved plans for event rephrasings, including "Dinner with Rubi" and "Rubi will have dinner with me." It offers Update Existing, flags unrelated overlapping events, and requires confirmation to keep another copy. Existing duplicates can be reviewed in My Plans; nothing is merged or deleted automatically. See [duplicate protection design and acceptance tests](docs/quality/SEMANTIC-DUPLICATE-PREVENTION.md).

## Remorrow Resolve — schedule-conflict assistant
When a proposed event conflicts with an event saved through Remorrow, the new **Resolve** flow asks which could move and offers up to three EventKit-checked alternatives. You can choose a different date before saving, explicitly move an editable saved event, or draft a proposal for shared events. **My Plans → Resolve schedule clashes** also handles overlapping saved events. No Calendar changes happen without approval. See [Resolve architecture and acceptance checks](docs/implementation/REMORROW-RESOLVE.md).
