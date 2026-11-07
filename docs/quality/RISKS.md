# Risk Register
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Date parser suggests incorrect day/year | High | High | Evidence and explicit confirmation; edge fixtures |
| Share Extension inconsistent provider payloads | High | Medium | Supported type matrix, manual fallback |
| Extension terminated mid-transfer | Medium | High | Atomic app-group handoff |
| Duplicate Calendar events on retry | Medium | High | Idempotency key + external IDs |
| Receipts omit actual return deadline | High | High | Require user's deadline confirmation |
| Alerts disabled or delayed by iOS | Medium | Medium | Explain permission and reliability limits |
| Personal content exposed in logs/analytics | Medium | High | No raw-content logging, local-first defaults |
| Poor conversion at $4.99 | High | Medium | Paid acquisition tests, pricing validation |
| Trademark conflicts for "Remorrow" | Unknown | High | Perform USPTO and App Store clearance |
| Xcode/entitlement configuration errors | Medium | Medium | Sprint 0 device spikes |
