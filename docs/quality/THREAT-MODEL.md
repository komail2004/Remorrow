# Lightweight Threat Model
## Assets
Shared private messages, screenshots, receipt images, event dates/locations, Calendar/Reminders permissions and local storage.

## Trust boundaries
1. External host app -> Share Extension input.
2. Extension -> App Group handoff -> main app.
3. OCR/model outputs -> untrusted proposal -> review.
4. User-confirmed action -> EventKit or UserNotifications.
5. Future backend (not MVP) -> remote content/data transfer.

## Threats and mitigations
| Threat | Impact | Mitigation / validation |
|---|---|---|
| Prompt injection in shared text | Unauthorized action | Treat content as data; model receives no write tools |
| Malicious/oversized image | Crash or denial of service | Bound extension resources; validate image and fail safely |
| Extension temporary content leak | Exposure | File protection, minimal retention, cleanup and deletion tests |
| Wrong inferred event or return expiry | Missed event/lost refund | Explicit review, evidence and uncertainty warnings |
| Duplicate save after retry | Calendar spam | Idempotency ID and external identifier reconciliation |
| Logs leaking addresses or receipts | Privacy violation | Structured logs without raw personal data |
| Revoked EventKit authorization | Failed operations | Check authorization and preserve draft |
| Notification preview on lock screen | Sensitive disclosure | Privacy-conscious, optionally generic notification text |
| Cloud API credentials in iOS binary | Key theft/cost | Cloud not shipped in MVP; future backend only |

## Privacy release gates
Device network traffic audit, accessibility of permissions, App Group cleanup, explicit deletion behavior, and accuracy of privacy disclosure. Never claim encryption specifics without a verified implementation.
