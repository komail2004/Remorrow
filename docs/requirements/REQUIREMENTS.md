# Requirements Register
**Version 0.1 · Draft · P0=MVP, P1=next, P2=future**

| ID | Priority | Requirement | Verification |
|---|---|---|---|
| FR-001 | P0 | Type/paste editable text | Works offline, retains draft |
| FR-002 | P0 | Accept shared plain text via Share Extension | Tested host apps, safe handoff |
| FR-003 | P0 | Accept user-shared screenshots/images | No broad Photos permission required |
| FR-004 | P0 | Select image from Photos | User-selected item loaded |
| FR-005 | P0 | OCR image into correctable text | Error state + text corrections |
| FR-006 | P0 | Propose dated action from content | Title/date/evidence shown |
| FR-007 | P0 | Flag missing or uncertain dates | No silently invented deadline |
| FR-008 | P0 | Editable review before writing | Cancel never writes |
| FR-009 | P0 | Create Calendar event via EventKit | Correct date/timezone & permission |
| FR-010 | P0 | Create system Reminder via EventKit | Correct fields & permission |
| FR-011 | P0 | Store shopping-return item | User confirms return expiry |
| FR-012 | P0 | Schedule/edit/cancel return alerts | Notification requests stay consistent |
| FR-013 | P0 | Upcoming dashboard | Items sorted by due date |
| FR-014 | P0 | Edit/delete local item | External changes clearly disclosed |
| FR-015 | P0 | Handle revoked/denied permissions | Draft retained; Settings guidance |
| FR-016 | P0 | Data deletion/privacy controls | Local content removal verified |
| FR-017 | P0 | Accessibility support | VoiceOver, Dynamic Type, contrast |
| FR-018 | P1 | Multiple actions per input | Independent review/confirmation |
| FR-019 | P1 | Recurring reminder suggestions | No duplicate/unsupported recurrence |
| FR-020 | P1 | More shared content types | Each provider/type tested |
| FR-021 | P1 | Widgets & App Shortcuts | Feasibility and refresh semantics |
| FR-022 | P2 | User-controlled export/backup | Private portable format |

## Nonfunctional
| ID | Target |
|---|---|
| NFR-001 | Local-first: no user-content network upload in MVP |
| NFR-002 | Target median capture-to-confirmation under 20 seconds |
| NFR-003 | Stable under share-extension termination and permission failure |
| NFR-004 | Accuracy reported from explicit fixtures, including abstentions |
| NFR-005 | Least-privilege entitlements and protected local storage |
| NFR-006 | Manual accessibility checks across critical flows |
| NFR-007 | Physical-device test matrix, iOS minimum version fixed in ADR |
| NFR-008 | Distinguish sourced facts from inferred suggestions |
| NFR-009 | Core capture and parsing function offline |
| NFR-010 | Data lifecycle and external-event synchronization documented |

All P0 stories must map to test cases and backlog IDs. Scope changes require edits to SRS, backlog and tests.

## Implementation amendments
| ID | Priority | Requirement | Verification |
|---|---|---|---|
| FR-023 | P0 | Provider-agnostic extraction protocol returns typed proposals only | Engine substitution test |
| FR-024 | P0 | Apple Intelligence capability detection and graceful local fallback | Unsupported/offline tests |
| FR-025 | P0 | Explicit source evidence and ambiguity status on proposals | UI snapshot and parser tests |
| FR-026 | P0 | Accessible review flow for multiple proposed actions or clear single-action limit | UI and VoiceOver tests |
| FR-027 | P0 | Error/empty/permission state design matches screen specs | UX acceptance matrix |
| FR-028 | P1 | Optional cloud model behind user opt-in and server-managed keys | Privacy + security review before enabling |
| NFR-011 | P0 | Engine produces no side effects: no EventKit writes or notifications | Mock integration test |
| NFR-012 | P0 | Source content not logged or uploaded by default | Offline/network traffic audit |
| NFR-013 | P0 | UI follows design tokens and accessibility guidelines | Design QA checklist |
| NFR-014 | P0 | Date handling and storage documented for DST and timezone cases | Calendar fixture tests |
