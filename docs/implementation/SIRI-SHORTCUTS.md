# Siri & Shortcuts — local-only capture

**Implemented:** `RememberWithRemorrowIntent` via Apple's App Intents framework. The intent accepts **explicitly provided** text from the Shortcuts app or Siri, validates a 20,000 character limit, writes an atomic JSON manifest to the existing App Group inbox, and responds that the user should open Remorrow to review.

The shortcut does **not** scan Messages in the background, cannot obtain an arbitrary selected message on demand, and does not create an EventKit item without user approval. It requires App Group provisioning for the containing app on a physical iPhone. In Shortcuts, search for "Remember with Remorrow", supply text (or connect a Copy to Clipboard/Get Clipboard action) and run it. The App Shortcut phrase allows Siri discovery, but the OS may still require prompting for text.

**Verification:** Xcode simulator compilation only verifies API integration, not Siri language recognition. Try with both Shortcuts and Siri on a provisioned device; test permission-denied App Group and selected-text content not being uploaded.
