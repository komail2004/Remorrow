# Prioritized Product Backlog
**Relative story points**, not time estimates. New tickets start Backlog.

| ID | Epic | Priority | Points | Outcome | Requirement |
|---|---|---|---:|---|---|
| RM-001 | Foundation | P0 | 2 | Configure Xcode app + tests + CI | NFR-007 |
| RM-002 | Foundation | P0 | 3 | Share Extension and EventKit feasibility spike | FR-002, FR-009 |
| RM-003 | Capture | P0 | 3 | Manual text and paste | FR-001 |
| RM-004 | Extraction | P0 | 5 | Candidate title/date detection; uncertainty | FR-006, FR-007 |
| RM-005 | Review | P0 | 5 | Editable candidate, explicit approval | FR-008 |
| RM-006 | Scheduling | P0 | 5 | Authorized Calendar save and retries | FR-009 |
| RM-007 | Scheduling | P0 | 5 | Authorized system Reminder save | FR-010 |
| RM-008 | Experience | P0 | 5 | Local storage + Upcoming dashboard | FR-013, FR-014 |
| RM-009 | Extraction | P0 | 5 | Image OCR + correctable output | FR-004, FR-005 |
| RM-010 | Capture | P0 | 8 | Share Extension for text and image | FR-002, FR-003 |
| RM-011 | Returns | P0 | 5 | Verified return deadlines, receipt info | FR-011 |
| RM-012 | Returns | P0 | 5 | Local alerts, edits and cancellation | FR-012 |
| RM-013 | Experience | P0 | 5 | Accessibility, privacy, permission recovery | FR-015–017 |
| RM-014 | Release | P0 | 3 | Device QA, TestFlight and App Store | NFR-001–010 |
| RM-015 | Extraction | P1 | 8 | Multiple action candidates | FR-018 |
| RM-016 | Integrations | P1 | 5 | Widgets/Shortcuts feasibility | FR-021 |

## Key acceptance checks
**RM-003:** offline text persists through Analyze and editable candidate/manual fallback.
**RM-004:** "Friday at 5" without context is treated as uncertain, not invented.
**RM-005:** cancel creates no system event or reminder.
**RM-006/007:** permission denial keeps draft; retry does not make duplicates.
**RM-009:** unreadable image offers editable fallback.
**RM-010:** sharing supported text/images works on physical iPhone and survives interruption.
**RM-011/012:** receipt with no explicit return deadline requires user confirmation; edits adjust pending alerts.
**RM-014:** all P0 tests pass before release.

## Dependencies
RM-001 -> 003 -> 004 -> 005 -> 006/007 -> 008. RM-009 -> 010. RM-011 -> 012. Quality and release gate every slice.

## Additional implementation-ready stories
| ID | Epic | Priority | Points | Outcome | Requirement |
|---|---|---|---:|---|---|
| RM-017 | Extraction | P0 | 3 | Model-neutral candidate contract & validator | FR-023, FR-025 |
| RM-018 | Extraction | P0 | 5 | Local rules parsing and failure fallback | FR-024, NFR-011 |
| RM-019 | Extraction | P1 | 8 | Evaluate Foundation Models on eligible hardware, measure accuracy | FR-024 |
| RM-020 | Experience | P0 | 5 | Reusable design components & accessible review flow | FR-026, FR-027 |
| RM-021 | Foundation | P0 | 3 | Local data lifecycle/retention and App Group contract | NFR-012, NFR-014 |
| RM-022 | Release | P0 | 3 | Beta analytics and pricing validation plan | NFR-013 |
| RM-023 | Extraction | P2 | 8 | Research opt-in cloud engine and protected backend | FR-028 |

**Critical sequence:** RM-001 -> RM-017/018 -> RM-003/004 -> RM-005/020 -> RM-006/007; RM-002 -> RM-009/010. These stories are specifications, not completed features. See the linked documentation before sprint planning.
