import Foundation
import NaturalLanguage

/// Conservative, entirely on-device interpretation of user-supplied text and OCR.
/// Produces suggestions, never writes to EventKit. Dates and commitment are ALWAYS reviewed.
struct LocalRulesEngine: ExtractionEngine {
    private static let datePattern = #"(?i)\b(?:today|tonight|tomorrow|day after tomorrow|(?:(?:this|next)\s+)?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday))\b"#
    private static let timePattern = #"(?i)\b(?:at|by|around|before)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b"#
    private static let actionWords = [
        "meet", "meeting", "dinner", "lunch", "breakfast", "appointment",
        "interview", "flight", "concert", "call", "remind", "remember",
        "submit", "assignment", "homework", "due", "deadline", "finish",
        "send", "pay", "return", "pickup", "pick up", "bring", "buy",
        "reservation", "exam", "test", "presentation", "class", "party",
        "visit", "doctor", "dentist", "schedule"
    ]

    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        let segments = Self.segments(from: text)
        var proposals: [ActionProposal] = []
        var seen = Set<String>()

        for segment in segments {
            let candidate = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            guard candidate.count >= 6 else { continue }
            // Chat timestamps, battery indicators and header dates are not commitments.
            guard Self.hasAction(candidate) else { continue }

            let dates = Self.detectDates(in: candidate, input: input)
            guard !dates.isEmpty else { continue }

            for date in dates {
                let title = SmartTitleGenerator.title(from: candidate, dateEvidence: date.evidence)
                guard title != "Review this reminder" else { continue }
                let key = title.lowercased() + "|" + (date.date.map { String(Int($0.timeIntervalSince1970 / 60)) } ?? date.evidence.lowercased())
                guard seen.insert(key).inserted else { continue }
                var flags = date.flags
                flags.append("confirmDate")
                flags.append("confirmActionType")
                if Self.isTentative(candidate) { flags.append("confirmCommitment") }
                proposals.append(ActionProposal(
                    kind: Self.suggestedKind(for: candidate),
                    title: title,
                    sourceEvidence: candidate,
                    proposedDate: date.date,
                    uncertaintyFlags: Array(Set(flags)).sorted(),
                    origin: .localRules
                ))
            }
        }
        return Array(proposals.prefix(12))
    }

    private struct DateCandidate {
        let date: Date?
        let evidence: String
        let flags: [String]
    }

    static func segments(from source: String) -> [String] {
        // OCR often places one chat bubble on several visual lines. A paragraph break
        // or sentence boundary is stronger evidence of a separate action.
        let normalized = source.replacingOccurrences(of: "\r", with: "\n")
        var output: [String] = []
        for raw in normalized.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            // Ignore isolated sender labels/timestamps rather than pairing them with
            // unrelated dates in nearby bubbles.
            guard !line.matches(#"(?i)^(?:\d{1,2}:\d{2}\s*(?:am|pm)?|today|yesterday|delivered|read|messages|imessage)$"#) else { continue }

            let tokenizer = NLTokenizer(unit: .sentence)
            tokenizer.string = line
            let boundaries = tokenizer.tokens(for: line.startIndex..<line.endIndex)
            let sentences = boundaries.isEmpty ? [line] : boundaries.map { String(line[$0]) }

            for sentence in sentences {
                // Split "dinner Thursday and submit paper Friday" only when each
                // side independently contains a date reference and an action.
                let pieces = sentence.components(separatedBy: #" and "#)
                if pieces.count == 2,
                   hasAction(pieces[0]), hasAction(pieces[1]),
                   mentionsDate(pieces[0]), mentionsDate(pieces[1]) {
                    output.append(contentsOf: pieces)
                } else {
                    output.append(sentence)
                }
            }
        }
        // OCR frequently wraps a single message bubble across multiple lines.
        // Join a dated line to the immediately preceding action line when
        // neither one alone could produce a complete proposal.
        var merged: [String] = []
        for piece in output {
            let item = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            if let previous = merged.last,
               hasAction(previous), !mentionsDate(previous),
               !hasAction(item), mentionsDate(item) {
                merged[merged.count - 1] = previous + " " + item
            } else {
                merged.append(item)
            }
        }
        return merged
    }

    private static func hasAction(_ text: String) -> Bool {
        let lower = text.lowercased()
        return actionWords.contains { lower.contains($0) }
    }

    private static func mentionsDate(_ text: String) -> Bool {
        if text.matches(datePattern) { return true }
        if text.matches(#"(?i)\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}\b"#) { return true }
        return text.matches(#"\b\d{1,2}[/\-]\d{1,2}(?:[/\-]\d{2,4})?\b"#)
    }

    private static func detectDates(in text: String, input: ExtractionInput) -> [DateCandidate] {
        var results: [DateCandidate] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: input.timeZoneIdentifier) ?? .current
        calendar.locale = Locale(identifier: input.localeIdentifier)

        if let match = text.firstMatch(datePattern),
           let range = Range(match.range, in: text) {
            let evidence = String(text[range])
            let day = dateFromRelative(evidence, reference: input.capturedAt, calendar: calendar)
            let time = extractTime(from: text)
            var flags = ["confirmRelativeDate"]
            if time.hour == nil { flags.append("timeNotSpecified") }
            if time.ambiguous { flags.append("confirmTime") }
            if let day {
                let dayStart = calendar.startOfDay(for: day)
                let result = calendar.date(bySettingHour: time.hour ?? 9,
                                           minute: time.minute ?? 0,
                                           second: 0,
                                           of: dayStart) ?? dayStart
                results.append(DateCandidate(date: result, evidence: evidence, flags: flags))
                return results
            }
        }

        // Absolute date fallback: only accept a match with a month/day or numeric
        // date. A lone 9:41 chat timestamp must never become an event.
        guard mentionsDate(text),
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        else { return results }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in detector.matches(in: text, options: [], range: range) {
            guard let date = match.date, let span = Range(match.range, in: text) else { continue }
            let evidence = String(text[span])
            guard evidence.matches(#"\d"#) else { continue }
            var flags: [String] = []
            if !evidence.matches(#"(?i)\b\d{4}\b"#) { flags.append("confirmYear") }
            if !evidence.matches(#"(?i)\b(?:am|pm)\b"#) &&
               !text.matches(#"(?i)\b(?:at|by|around)\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)\b"#) {
                flags.append("confirmTime")
            }
            results.append(DateCandidate(date: date, evidence: evidence, flags: flags))
        }
        return results
    }

    private static func extractTime(from text: String) -> (hour: Int?, minute: Int?, ambiguous: Bool) {
        guard let match = text.firstMatch(timePattern) else { return (nil, nil, false) }
        let ns = text as NSString
        guard match.range(at: 1).location != NSNotFound,
              let rawHour = Int(ns.substring(with: match.range(at: 1))),
              (1...23).contains(rawHour) else { return (nil, nil, true) }
        let minute = match.range(at: 2).location == NSNotFound
            ? 0 : (Int(ns.substring(with: match.range(at: 2))) ?? 0)
        guard minute < 60 else { return (nil, nil, true) }
        let suffix = match.range(at: 3).location == NSNotFound
            ? "" : ns.substring(with: match.range(at: 3)).lowercased()
        if suffix == "" { return (nil, nil, true) }
        if rawHour > 12 { return (nil, nil, true) }
        let hour = suffix == "pm" ? (rawHour % 12) + 12 : rawHour % 12
        return (hour, minute, false)
    }

    private static func dateFromRelative(_ phrase: String, reference: Date, calendar: Calendar) -> Date? {
        let value = phrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "today" || value == "tonight" { return reference }
        if value == "tomorrow" { return calendar.date(byAdding: .day, value: 1, to: reference) }
        if value == "day after tomorrow" { return calendar.date(byAdding: .day, value: 2, to: reference) }
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        guard let index = names.firstIndex(where: { value.contains($0) }) else { return nil }
        let weekday = index + 1
        var delta = (weekday - calendar.component(.weekday, from: reference) + 7) % 7
        if delta == 0 { delta = 7 }
        // "next Monday" has varied colloquial meaning; mark ambiguity and
        // suggest the next occurrence instead of asserting a particular week.
        return calendar.date(byAdding: .day, value: delta, to: reference)
    }

    private static func isTentative(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["maybe", "might", "possibly", "if we", "not sure", "tentative", "could meet"].contains {
            lower.contains($0)
        }
    }

    private static func suggestedKind(for text: String) -> ProposedActionKind {
        let lower = text.lowercased()
        let reminders = ["remind", "remember", "don't forget", "submit", "finish", "pay", "buy",
                         "send", "return", "cancel", "prepare", "homework", "assignment", "due"]
        if reminders.contains(where: { lower.contains($0) }) { return .reminder }
        let events = ["meeting", "meet with", "dinner", "lunch", "appointment", "concert",
                      "interview", "flight", "party", "reservation", "presentation", "exam"]
        if events.contains(where: { lower.contains($0) }) { return .calendarEvent }
        return .reminder
    }
}

private extension String {
    func firstMatch(_ pattern: String) -> NSTextCheckingResult? {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        return expression.firstMatch(in: self, range: NSRange(startIndex..<endIndex, in: self))
    }

    func matches(_ pattern: String) -> Bool {
        firstMatch(pattern) != nil
    }
}
