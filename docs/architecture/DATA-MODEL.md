# Local Data Model and Lifecycle — proposal
## Entities
- **Capture**: UUID, sourceType (typed/sharedText/sharedImage/selectedImage), capturedAt, timezoneID, localeID, optional rawText, optional ephemeralImageReference, processingStatus.
- **ActionProposal**: UUID, captureID, kind (event/reminder/return), evidence text, title, optional candidateDate, uncertainty flags, engine origin. Never authority for external changes.
- **SavedAction**: UUID, kind, edited title/date/timezone, status, optional EventKit externalIdentifier, createdAt/updatedAt, source reference.
- **ReturnItem**: UUID, merchant?, itemName, price?, currency?, purchaseDate?, **confirmed** deadline, alert offsets, optional user-kept receipt path, state.
- **AlertRecord**: UUID, action/return ID, localNotificationIdentifier, scheduledDate, status.

## Invariants
- Review/confirm boundary is authoritative; no EventKit write from parsing or OCR.
- A return deadline is user-confirmed; purchase date cannot substitute.
- Repeated save must be idempotent or explicitly warn; track external IDs and failed states.
- Time zone must persist with date interpretation; events crossing DST require user review.
- Deletion of local records and linked EventKit objects must have clearly documented independent choices.

## Persistence
SwiftData local store is proposed. App Group handoff is temporary and should be deleted after successful import or expiration; define a deterministic TTL. File protection and minimal logs. Avoid storing an original screenshot unless the user intentionally opts to keep it.

## Migration and backup
Version data model with migrations; no assumptions about iCloud synchronization in MVP. Describe device backup and deletion semantics accurately. Test migration with sanitized fixtures before each release.

## Privacy boundary
MVP sends no personal input off-device; user-controlled EventKit writes are platform data operations. Any future cloud inference requires new consent, threat model, policy and secure server credentials.
