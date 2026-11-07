# ADR-0001: Local-first architecture
**Status:** Accepted for MVP
## Context
Capture content can include personal texts, appointments, addresses and receipts. A backend would increase privacy, cost and complexity.
## Decision
Use on-device OCR, parsing and local storage for MVP; no automatic remote processing. Any future cloud capability must be opt-in, explained and governed by a separate ADR.
## Consequences
Offline operation and simpler privacy story. Advanced semantic extraction may be limited; uncertainty requires review instead of invented confidence.
