# Sprint 0 — Foundation and feasibility
**Goal:** A repeatable iPhone development environment with proven critical platform integrations.

## Planned work
- [ ] RM-001: Create and check in an actual Xcode project with main app and test target.
- [ ] Choose supported iOS deployment target and document rationale (ADR).
- [ ] Configure signing/bundle identifiers and safe placeholder App Group entitlements.
- [ ] Establish Swift lint/build/test strategy and macOS runner CI.
- [ ] RM-002: Test EventKit access flow with permission allow/deny/revoke.
- [ ] RM-002: Test Share Extension receiving sample text and screenshot.
- [ ] Evaluate local parser options (Foundation, Data Detectors) with ambiguous date fixtures.
- [ ] Create sanitized test-data fixtures and define retention behavior.

## Exit criteria
App launches on real device; working share input can be observed; permissions can be requested and rejected without crash; architectural unknowns documented; smoke test recorded.

## Risks and review
Share Extension process lifecycle and capabilities, minimum OS support, privacy entitlements. Demo the device workflow and update backlog estimates.

## Design and AI discovery additions
- [ ] Establish design tokens and verify iOS native control ergonomics on smaller iPhone and large text.
- [ ] Run local parser fixtures, document extraction errors and fallback outcomes.
- [ ] Confirm Foundation Models framework/runtime availability and supported iPhones with current Xcode SDK and physical device.
- [ ] Decide the local storage retention model and App Group isolation before implementing the Share Extension.
- [ ] Record baseline capture -> review -> confirm UX time and accessibility checks with sanitized samples.
- [ ] Validate no network dependency or silent external writes.

