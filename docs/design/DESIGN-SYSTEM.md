# Remorrow Design System v0.1
**Product direction:** elevated, calm, friendly, useful. Gen Z-friendly but not gimmicky. Native-first iOS.

## Brand attributes
Uncomplicated, trustworthy, warm, quietly playful. The product makes everyday clutter feel organized. Keep copy conversational and avoid false certainty or "AI magic" hype.

## Visual tokens (proposals, validate in actual designs)
| Token | Light | Dark | Purpose |
|---|---|---|---|
| Background | #F7F5F1 | #121419 | Main canvas |
| Surface | #FFFFFF | #20242D | Cards |
| Primary text | #20242B | #F4F4F6 | Readable content |
| Secondary text | #656976 | #B7BAC5 | Supporting metadata |
| Accent | #6C5CE7 | #AA9AFF | Actions and focus |
| Success | #287A54 | #71CDA1 | Confirmed status |
| Caution | #9B6418 | #E5B15E | Uncertain fields |
| Error | #B33B46 | #F28B91 | Clear error feedback |

These colors are **design proposals**; validate actual WCAG contrast in context before shipping. Never use hue as the only status cue.

## Typography
Use San Francisco via system text styles with Dynamic Type. Primary title .largeTitle/.title, card title .headline, metadata .subheadline/.caption. Do not hardcode UI fonts that break accessibility.

## Components
- Primary filled CTA: "Review reminder", "Save to Calendar", "Add Reminder".
- Secondary buttons for editing, rescheduling or choosing destination.
- Evidence chip: short quoted source excerpt.
- Date field: visible date, timezone and explicit "Needs confirmation" state.
- Suggestion card: icon, kind, title, date, evidence and edit affordance.
- Return card: merchant, item, *confirmed* last-return date, countdown and optional receipt.
- Status variants: Draft, Needs review, Scheduled, Completed, Expired, Permission needed, Error.
- Empty state: one concrete next action; no guilt-inducing illustrations.
- Skeleton/loading: bounded; always allow cancel and retry.

## Motion and haptics
Short subtle transitions and confirmation feedback. Respect Reduce Motion and Reduce Transparency. No unnecessary animations in the review flow.

## Interaction ergonomics
44pt minimum touch targets, thumb-accessible bottom CTA, one primary action per screen, clear back/cancel behavior. Never silently auto-save extracted text.

## Icon and App Store direction
Abstract folded bookmark + calendar tick, not a generic brain/sparkles. Test at small app icon sizes, avoid text inside icon. Trademark/name clearance remains outstanding.

## Definition of a polished screen
Readable at large text, supported in light/dark, VoiceOver verified, empty/loading/error/permission states designed, dates and time zones unambiguous, no marketing claim unsupported by real behavior.

## Implemented November 2026 visual revision
The initial lavender/violet palette above is superseded. The app now uses warm off-white, an evergreen accent, native adaptive card surfaces, editorial serif display typography and a custom dark-ink/gold hourglass identity. The Today screen prioritizes user data over promotional visuals. Real-device contrast and accessibility still need validation.
