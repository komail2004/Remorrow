# Remorrow iOS Share Extension
## Scope
- Share **one selected** screenshot/image, text or link from a compatible iOS host app.
- Shared item is atomically written as a temporary file in an App Group container, never auto-scheduled.
- On Remorrow app launch/foreground, import content, OCR selected images, then open editable review before saving.
- If extraction fails, keep content for retry or manual paste.
- The extension cannot silently read all messages or auto-open the full app in every host.

## Provisioning steps
1. In Apple's Developer portal enable an App Group `group.com.komail.Remorrow` (or replace it consistently).
2. Register the group for **both** bundle identifiers `com.komail.Remorrow` and `com.komail.Remorrow.ShareExtension`. Replace IDs with your own team namespace if needed.
3. In Xcode enable Automatically manage signing for both targets; choose your Apple Development Team; regenerate project using XcodeGen if modifying `project.yml`.
4. Test on device by sharing text from Notes and an image from Photos, then open Remorrow to review.
5. In Simulator with CODE_SIGNING_ALLOWED=NO compilation can succeed even if the App Group is not provisioned; functional share handoff still requires capability testing.

## Known limitations
The Share Extension stages content and asks user to open Remorrow to review. Safari URLs are saved as URL strings, not scraped webpage content. The consumer currently imports one queued item per activation; queue management and cleanup policies are follow-ups. Test large images, host variants, interruption, and receipt privacy. No event is written without confirmation.
