# Fixing Shortcuts “client is not entitled” / SharedInboxError

## Cause
An earlier version of `RememberWithRemorrowIntent` accessed
`FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`
inside the App Intent. On an iOS Simulator or a build without the registered
App Group entitlement, this fails with **client is not entitled** and
`Remorrow.SharedInboxError error 1`.

## Implementation
- **Siri & Shortcuts** now write the explicitly provided text to
  `Application Support/Remorrow/ShortcutInbox` within the *containing app's
  private sandbox*. This avoids the App Group permission requirement for
  app-owned Intents. The write is atomic and remains local.
- **Share Extension / selected-text Action Extension** continue using
  `group.com.komail.Remorrow/Inbox`. These are separate app-extension
  processes and still require a properly registered App Group for transfers.
- The main app imports from **both** folders on launch/foreground, then uses
  the same existing editable review screen. It never automatically schedules
  an item from shortcut text.
- Test coverage checks private staging, reading/removal and invalid input.

## Verify in Simulator
1. `git pull origin main`, `xcodegen generate`, open Remorrow.xcodeproj.
2. Build & run **Remorrow**. If you have stale builds, Product → Clean Build
   Folder, then reinstall Remorrow in the simulator. You may need to remove
   an old Shortcuts action and add the new one.
3. Open Shortcuts → Remorrow → Remember; provide sample text (“Submit the
   report Friday at 3 PM”) and run it.
4. Expected: **Saved privately. Open Remorrow to review the reminder.**
5. Open Remorrow; check that the original text is loaded and review is
   displayed before anything is written to Calendar or Reminders.

## For device and extension features
In Apple Developer / Xcode Signing & Capabilities, ensure the App Group
`group.com.komail.Remorrow` is registered under your Team and selected for
**Remorrow**, **RemorrowShareExtension**, **RemorrowTextAction**, and
**RemorrowWidget**. All targets need compatible provisioning profiles;
bundle IDs must belong to your Team. A source-code entitlement plist alone
does not guarantee that the installed app is entitled.

To investigate the installed binary from the Mac, use Xcode's build products
and `codesign -d --entitlements :- <path-to-signed-Remorrow.app>`; also
inspect embedded extension bundles. Do not treat a successful no-sign
simulator CI build as proof of Apple Developer provisioning.

This fallback is for App Intents in the containing app; it does **not**
grant an extension access to another app's private sandbox.
