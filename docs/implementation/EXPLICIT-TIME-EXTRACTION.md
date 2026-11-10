# Explicit-time extraction safety fix

The message **"Dinner with ruby at 7pm"** has a verified clock time but **no verified date**. Previously LocalRulesEngine dropped all proposals without a calendar day, and the Apple Foundation Models result used Review's default current time + 1 hour. The user saw 9:37 PM despite writing 7 PM.

`ExplicitTimeParser` now recognizes unambiguous AM/PM times (with or without "at"), minute precision, noon/midnight, and explicit 13:00–23:59 notation. It does not treat bare "7", month/day numbers, or chat headers as verified times. LocalRulesEngine returns a suggestion containing the verified clock hour/minute while deliberately leaving `proposedDate = nil`.

Review shows the recognized time at an illustrative upcoming day, identifies that the **day was not supplied**, and requires a **user verification toggle** before Save or Update. Apple's language-model classification carries forward the locally parsed hour/minute, rather than inventing a time. Absolute/relative date detections reuse the same deterministic time parser.

Tests cover 7 PM, 7:45 p.m., 12 AM/PM, 24-hour time, OCR line wraps, real date+time, no-date safety, and picker times before/after the current clock time. This is local-only; no EventKit changes are made before the user confirms.

A simulator build and unit tests are required before release; verify on a provisioned physical iPhone with typed text, selected-text Shortcuts, and OCR screenshots.
