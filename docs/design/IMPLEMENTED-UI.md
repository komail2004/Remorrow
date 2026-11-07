# Remorrow Visual Prototype — 2026-11-06

## Purpose
Polished, working SwiftUI prototype for opening in Xcode, not mock screenshots.

## Implemented visual language
- Warm adaptive canvas, cards with rounded continuous geometry, deep violet accent and gradient editorial hero.
- Brand lockup, small uppercased section eyebrows, native San Francisco rounded display typography.
- Home with intelligent quick-capture composer, screenshot picker, upcoming preview, and local privacy message.
- My Plans with real SwiftData saved items; no fake bookings, counts or example records.
- Settings showing verified local-first behavior (not a permission-management dashboard yet).
- Review sheet with editable title, destination selector and native graphical calendar.
- `#Preview` declarations for Home and Review, with an in-memory SwiftData container for Home.

## Functionality preserved
Typed capture and editable draft, Vision screenshot OCR, offline date detection, explicit review, EventKit save and SwiftData saved history. No simulated event data.

## Still pending
Share Extension, polished returns tracker, multiple extracted actions, editing/deleting saved external events, Apple Foundation Models integration, comprehensive notifications, real-device UX checks. Brand colors must be contrast-validated; preview is not production signoff.

## Xcode
Run `brew install xcodegen` once on Mac; `xcodegen generate` from repo root; open `Remorrow.xcodeproj` and select Remorrow scheme. Select your signing team for device testing. The app targets iOS 17 or later.

Inspect the previews in `ContentView.swift` and `ReviewView.swift` (Editor > Canvas). The Review preview uses a fabricated example; the live app starts with no saved records.
