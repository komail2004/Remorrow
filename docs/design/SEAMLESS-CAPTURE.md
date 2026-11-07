# Frictionless capture strategy — Remorrow

## UX hierarchy
1. **Best:** Select content in a compatible app, tap the system Share menu, choose Remorrow. The current native Share Extension queues text or an image and shows a "Saved for review" message; opening Remorrow imports it and presents editable review.
2. **Messages fallback:** Long-press a particular text message, tap Copy; switch to Remorrow and tap **Paste & analyze**. This explicit tap reads the clipboard and starts interpretation immediately.
3. **Screenshot:** Capture a screenshot, select it in Photos, Share to Remorrow or use **Add screenshot** in Remorrow.
4. **Manual:** Type or paste into the composer and tap Find what matters.

## Why we do not secretly read messages
iOS does not grant general third-party apps permission to monitor an iPhone's Messages database or automatically inspect every received message. Remorrow should not pretend otherwise. iOS share providers differ: some offer selected text to the share sheet, some only permit Copy or screenshot.

## Further improvements to evaluate
- App Intents / Siri Shortcuts to offer a "Remember this" action for explicitly provided text (needs supported OS API review and implementation).
- Dedicated system notification or widget after user-controlled capture, without unsolicited clipboard reads.
- Share Extension inline preview, queue management and explicit "Open Remorrow" guidance; avoid unsupported attempts to force-open the app.
- Future Apple Foundation Models interpretation for multi-intent messages, on supported hardware; preserve local parser fallback.

## Privacy and reliability
- Clipboard read happens **only** when the user taps Paste & analyze. No polling, boot-time paste or background inbox scanning.
- The Share Extension only accepts user-selected content; no automatic iMessage access.
- OCR and parsing stay local in MVP, and external Calendar/Reminders writes still require confirmation.
- Test source apps: Messages copy flow, Photos image share, Notes text share, Safari URL share, Files image share where supported.

## Simulator image fixture import
Download the separately provided `Remorrow-Simulator-Test-Images.zip` and extract it to a folder on your Mac. With iPhone Simulator booted, run:
```bash
xcrun simctl addmedia booted ~/Downloads/Remorrow-Test-Images/*.png
```
Adjust the path to where you extracted the ZIP. Open Photos in Simulator; images appear in the library. In Remorrow, choose Add screenshot and test. All sample messages/receipts are synthetic.
