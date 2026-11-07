# Voice, Microcopy, and Accessibility

## Voice
Warm, direct, confident about user control; humble about uncertain AI extraction. Examples:
- Good: "We found two dates. Check them before saving."
- Good: "This looks like a return, but we couldn't determine the deadline."
- Good: "You can still add a reminder manually."
- Avoid: "AI understood everything perfectly"; "Never miss anything again"; "Guaranteed on-time alert."

## Empty/error strings
- Empty Home: "Nothing on your radar yet. Paste a message or share a screenshot."
- OCR failed: "We couldn't read that image. Try a clearer screenshot or type the details."
- Missing date: "We found something to remember, but not when. Choose a date."
- Denied calendar: "Calendar access is off. Your draft is safe; you can enable access in Settings."
- Fallback: "This device supports basic date detection. Please check the details."
- Return expiry: "Confirm the last day you can return this item."

## Accessibility
- Native text styles and accessible controls; no tiny fixed text.
- VoiceOver announces candidate kind, title, date, uncertainty and actions in logical order.
- Labels should not repeat visual ambiguity; "Date needs confirmation" is explicit.
- Touch targets >=44x44 pt; visible focus, strong contrast; no reliance on only color or haptics.
- Content available in Reduce Motion, Dark Mode, larger type, and Voice Control/dictation.
- Calendar dates formatted respecting locale/timezone and read unambiguously aloud.
- Include privacy-preserving UI tests and manual VoiceOver audits in DoD.
