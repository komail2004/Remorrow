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
**Planning / Sprint 0.** SwiftUI source is a lightweight scaffold. No complete Xcode project, shipping OCR, calendar integration or functional Share Extension is claimed yet. Configure an Xcode iOS project and app/extension targets before compiling.

## Development
Use GitHub Issues linked to requirement IDs, short-lived feature branches, pull requests and the [Definition of Done](docs/agile/DEFINITION-OF-DONE.md). Never add private user content or secrets to Git.

## Further specifications (November 2026)
- [Hybrid AI implementation](docs/architecture/AI-IMPLEMENTATION.md) · [ADR-0003](docs/architecture/ADR/0003-hybrid-intelligence.md)
- [Design system](docs/design/DESIGN-SYSTEM.md) · [Screen specifications](docs/design/SCREEN-SPECS.md) · [User flows](docs/design/USER-FLOWS.md)
- [Content and accessibility](docs/design/CONTENT-ACCESSIBILITY.md) · [Information architecture](docs/design/INFORMATION-ARCHITECTURE.md)
- [Data model](docs/architecture/DATA-MODEL.md) · [Threat model](docs/quality/THREAT-MODEL.md)
- [Analytics / experiment plan](docs/product/METRICS-EXPERIMENTS.md) · [Launch gates](docs/release/RELEASE-GATES.md)

The `Remorrow/Sources/Intelligence` files define model-neutral output types and interfaces; production model wiring, app target configuration, and real iPhone verification remain to be implemented.
