# First working slice — implementation notes
**Status:** Code committed; Xcode and physical-device verification pending.

## Scope delivered
- Reproducible XcodeGen project manifest targeting iOS 17+.
- Typed text editor with draft persistence via AppStorage.
- Local date candidate detection (NSDataDetector), explicit review before any system write.
- Photo picker with local Vision OCR and editable transcript.
- Review screen allows title, kind and date changes; save only after confirmation.
- EventKit integration for Calendar events and Apple Reminders (permission-gated).
- SwiftData local recently-saved history.
- Initial unit tests and macOS CI workflow.

## Known limitations and decisions
- This is **not** finished Share Extension support; user must paste or select a photo in-app.
- Model-backed semantic understanding remains a future integration; the simple date parser can miss multiple or relative actions.
- No shopping-return flow or local notification scheduling yet.
- Event duration is provisionally one hour and requires an editable duration before release.
- Saved action history doesn't yet support editing, deletion or external synchronization.
- Need idempotency key/transaction recovery so interruption after external write doesn't duplicate a save.
- Dates are suggested and reviewed; parser isn't guaranteed to respect all locale/timezone expressions.
- Source was not compiled in this environment (macOS/Xcode unavailable); CI and device builds must prove compatibility.

## First verification tasks
1. Run `brew install xcodegen`, `xcodegen generate` and open Remorrow.xcodeproj.
2. Set Apple development team and choose a supported simulator/physical device.
3. Build and run tests. Repair any SDK/compiler issues before marking RM-001 complete.
4. Test text/date detection, permissions, OCR and error states on device.
5. Build Share Extension and user-confirmed return flows in subsequent stories.
