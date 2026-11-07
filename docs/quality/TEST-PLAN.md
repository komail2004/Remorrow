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
