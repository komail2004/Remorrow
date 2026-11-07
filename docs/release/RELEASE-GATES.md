# Release Readiness Gates

## G0 Engineering readiness
Buildable Xcode project, correct signing, CI, tested Share Extension payloads and Apple framework availability on selected supported hardware.

## G1 Core functional integrity
All P0 acceptance cases pass: capture, OCR, parse/abstain, review, confirm, EventKit writes, return alerts, edit/delete, duplicates and recovery.

## G2 Privacy and safety
No hidden uploads, untrusted model output never invokes writes, App Group cleanup tested, local content deletion works, no private text in analytics/logs, accurate permissions and App Store privacy declarations.

## G3 Quality and accessibility
VoiceOver, Dynamic Type, Dark Mode, Reduce Motion, date/timezone accuracy, device/OS matrix, no known crash or data-loss issues.

## G4 Beta evidence
TestFlight real users, documented bug triage, OCR/parser correction data, successful capture->save task times, support path and privacy policy.

## G5 Commercial launch
Brand/name clearance, App Store listing and $4.99 price configuration verified, screenshots match actual shipping features, purchase funnel and acquisition budget measured.

## Decision
No App Store submission until the owner signs off G0–G5. Stage-specific exceptions require written rationale and risks.
