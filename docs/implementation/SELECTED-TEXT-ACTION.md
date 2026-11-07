# Selected-text Action Extension (local-only)
**Status:** Implemented in source, pending host-app and physical-device verification.

## Why
iOS does not give Remorrow permission to read iMessage conversation databases. Instead, the user selects text in a host app that supports passing text through the iOS share/action flow. The action appears as **Remember with Remorrow** in supported system Share/Actions interfaces.

## Behavior
1. Select text in Notes, Safari (selected webpage text), or another app that actually provides plain text to iOS actions.
2. Choose **Share** (and **Remember with Remorrow**, if exposed; the action may be in the share sheet's Actions area or under Edit Actions).
3. A small Remorrow screen previews the user-provided text. It remains editable.
4. Tap **Save for review**. The extension writes a JSON manifest to the *existing* private App Group inbox. It does not add any Calendar event.
5. Open Remorrow; it imports that content and opens the existing editable confirmation screen. No network requests or phone number.

## Limitations
- The action can only receive content actually shared by the host app. Some apps do not offer Share on selected text; **Messages cannot be made to expose its private message bubbles through this extension**. For Messages, use screenshot or Copy → Remorrow Paste.
- iOS determines share/action availability, ordering, and whether text selection includes Share. This is not a global text-selection-menu injection.
- Does not silently launch the containing app. User opens Remorrow after staging.
- iOS App Group `group.com.komail.Remorrow` must be provisioned for **Remorrow**, **RemorrowShareExtension**, and **RemorrowTextAction**.
- Saving happens only after the explicit action tap. All message contents remain on-device, and Calendar/Reminders writes still require explicit review.

## Testing
- Regenerate Xcode project, sign all three targets, install on physical iPhone.
- In Notes, select a sentence and use Share, check action availability. Safari may share a URL instead of selection depending on how invoked; inspect preview before saving.
- Check that review happens in Remorrow, that only the chosen text is imported, and that save/cancel/errors work without data loss.
- Test an unsupported host and denied/missing App Group configuration.
- Run `xcodegen generate` and simulator build + tests.
