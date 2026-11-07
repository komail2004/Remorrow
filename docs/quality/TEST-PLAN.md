# Test Strategy
**Test levels:** unit, integration, UI/accessibility, manual device acceptance, TestFlight.

## Test cases (initial)
| ID | Scenario | Pass condition |
|---|---|---|
| TC-001 | Paste text without network | Editable capture retained |
| TC-002 | Ambiguous "5/6" | Date needs clarification |
| TC-003 | "tomorrow" near DST change | Time zone and ambiguity handled |
| TC-004 | Image with no readable text | Manual fallback, no crash |
| TC-005 | Cancel review | No EventKit write |
| TC-006 | Deny Calendar/Reminder permission | No data loss, useful explanation |
| TC-007 | Confirm valid event | One correct system event created |
| TC-008 | Retry failed save | No duplicates |
| TC-009 | Change return deadline | Old scheduled alerts removed, new ones scheduled |
| TC-010 | Delete return item | Pending alerts canceled; local data removed |
| TC-011 | Share screenshot from tested host app | Secure and recoverable handoff |
| TC-012 | VoiceOver / Dynamic Type | Core flow accessible |
| TC-013 | Device in airplane mode | Core flows remain functional |
| TC-014 | Time zone switch after creating event | Approved scheduled time preserved or clearly explained |
| TC-015 | Receipt has purchase date but no return deadline | User must supply/verify expiry |

## Test fixtures
Use fabricated messages, synthetic receipts, locale/date variants and generated image fixtures. Never store real personal screenshots in source control.

## Gates
Every P0 requirement has explicit pass/fail record; app and extension must be tested on at least two real supported iPhone configurations if available; no known data-loss or privacy blockers at launch.

## Hybrid AI / UX additional scenarios
| ID | Scenario | Expected |
|---|---|---|
| TC-016 | Apple model unsupported/unavailable | Local parser selected without crash or misleading label |
| TC-017 | Model returns invented date/place | Validator rejects unsupported claims; UI requests clarification |
| TC-018 | Multi-action text with conflicting dates | Independent proposals or explicit limited-support message |
| TC-019 | Image OCR errors or low-quality photo | Editable transcript and manual fallback |
| TC-020 | User denies notifications | Saved event persists; no claim alert will arrive |
| TC-021 | VoiceOver and 200%+ text scaling | All capture/review controls reachable and understandable |
| TC-022 | Offline execution while parsing | No user content leaves device |
| TC-023 | Unknown merchant return policy | Confirmation required; no guessed expiry |
| TC-024 | Retry same external save | At most one external event/reminder |
| TC-025 | Source text contains prompt injection | Treated as data; no unauthorized tools or silent writes |

Verification must include real-device tests for Foundation Models availability, Share Extension behavior, event/reminder permissions, and notifications. Test fixtures are fabricated, never personal receipts or messages.

## Screenshot conversations and first-run guide (November 2026)
| ID | Scenario | Expected |
|---|---|---|
| TC-026 | Screenshot has two independent dated plans | Two separate editable suggestions, no automatic saves |
| TC-027 | OCR text spans two lines within one bubble | Joined into one action; original screenshot still available |
| TC-028 | Date and action are in separate chat bubbles | No cross-bubble invented event |
| TC-029 | Screenshot header says 9:41 / Today / Read | No task from UI chrome |
| TC-030 | "Maybe dinner Friday" | Explicit tentative-commitment warning |
| TC-031 | "Submit homework tomorrow" with no time | Visible unverified-time warning |
| TC-032 | User skips a proposal | No external save, moves to next suggestion |
| TC-033 | User partially saves then cancels | No stale content prompting duplicate save |
| TC-034 | User selects screenshot from Photos | OCR and analysis open review automatically |
| TC-035 | New installation first launch | Three-screen visual guide appears with Skip |
| TC-036 | Skip/restart | Guide is not shown again automatically |
| TC-037 | Guide reopened from Settings | Optional walkthrough opens without resetting stored plans |
| TC-038 | Selected-text Action Extension | Only explicitly shared text is queued, user must approve |
| TC-039 | Multiple shared items | Oldest imported first; no private data transferred over network |

**Automated coverage:** LocalRulesEngine and ConversationExtractionTests use synthetic text for TC-026..031. TC-032..039 require integration/UI tests and real-device verification before release. An XCTest simulator build is *not* equivalent to successful iPhone sharing/camera/permissions testing.
