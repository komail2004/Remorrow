import Foundation
import NaturalLanguage

/// Deterministic privacy-preserving title suggestions. This is not an LLM.
/// Always editable in Review; preserves source text for later inspection.
enum SmartTitleGenerator {
    static func title(from source: String, dateEvidence: String? = nil) -> String {
        var result = source.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Prefer one clear sentence rather than a whole pasted conversation.
        if let first = result.components(separatedBy: .newlines).first, !first.isEmpty {
            result = first
        }
        // Prefer the first actionable sentence over conversational small talk.
        // A capture like "Hi, how are you. Let's dine Saturday" should not
        // become a reminder called "How are you".
        let sentenceParser = NLTokenizer(unit: .sentence)
        sentenceParser.string = result
        let sentences = sentenceParser.tokens(for: result.startIndex..<result.endIndex)
            .map { String(result[$0]).trimmingCharacters(in: .whitespacesAndNewlines) }
        if sentences.count > 1 {
            let actionPattern = #"(?i)\b(?:dinner|dine|supper|lunch|meet|meeting|appointment|submit|send|pay|buy|return|flight|presentation|assignment|call|bring|pick up|remember|remind|don't forget)\b"#
            if let relevant = sentences.first(where: {
                $0.range(of: actionPattern, options: .regularExpression) != nil
            }) {
                result = relevant
            }
        }
        let prefixes = [
            #"(?i)^(?:hey|hi|hello)[!,.:\s]+"#,
            #"(?i)^(?:please\s+)?(?:can|could|would)\s+you\s+(?:please\s+)?(?:remind\s+me\s+to\s+|remember\s+to\s+)?"#,
            #"(?i)^(?:please\s+)?(?:remind\s+me\s+to|remember\s+to|don't\s+forget\s+to|note\s+to|reminder\s*[:\-]|todo\s*[:\-]|task\s*[:\-])\s*"#,
            #"(?i)^(?:just\s+)?(?:a\s+)?(?:quick\s+)?reminder(?:\s+that)?\s*[:,\-]?\s*"#,
            #"(?i)^(?:i\s+need\s+to|we\s+need\s+to|make\s+sure\s+to)\s+"#,
            #"(?i)^(?:please\s+)"#
        ]
        for prefix in prefixes {
            result = result.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
        }
        if let dateEvidence, !dateEvidence.isEmpty {
            result = result.replacingOccurrences(of: dateEvidence, with: "", options: [.caseInsensitive])
        }
        result = result.replacingOccurrences(of: #"(?i)\b(?:tomorrow|tonight|today|next\s+(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday))\b"#,
                                             with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"(?i)\b(?:at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b"#,
                                             with: "", options: .regularExpression)
        result = result.replacingOccurrences(
            of: #"(?i)\s+(?:on|by)\s+(?:(?:this|next)\s+)?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s+(?:the\s+)?\d{1,2}(?:st|nd|rd|th)?)?\b"#,
            with: "", options: .regularExpression
        )
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",.;:!?-–")))
        // Removing a date often leaves a dangling "on", "by", or "at".
        result = result.replacingOccurrences(of: #"(?i)\s+(?:on|at|by|before|around|for)$"#,
                                             with: "", options: .regularExpression)
        // Normalize an explicit participant and meal into a succinct event:
        // "Rubi will have dinner with me" -> "Dinner with Rubi".
        let mealPattern = #"(?i)^([a-z][a-z' -]{0,35}?)\s+(?:will|would|is going to|wants to|plans to)\s+(?:have\s+)?(dinner|supper|lunch|breakfast)\s+with\s+me\b"#
        if let regex = try? NSRegularExpression(pattern: mealPattern),
           let match = regex.firstMatch(in: result,
                                        range: NSRange(result.startIndex..<result.endIndex, in: result)),
           let personRange = Range(match.range(at: 1), in: result),
           let mealRange = Range(match.range(at: 2), in: result) {
            let person = String(result[personRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let meal = String(result[mealRange]).lowercased() == "supper"
                ? "Dinner" : String(result[mealRange]).capitalized
            result = meal + " with " + person
        }
        result = result.replacingOccurrences(of: #"(?i)^let['’]?s\s+dine\b"#,
                                             with: "Have dinner", options: .regularExpression)
        if let separator = result.firstIndex(where: { ".;\n".contains($0) }) {
            let first = String(result[..<separator])
            if first.count >= 7 { result = first }
        }
        if result.count > 74 {
            result = String(result.prefix(74))
            if let cut = result.lastIndex(of: " "), cut > result.startIndex {
                result = String(result[..<cut])
            }
        }
        guard !result.isEmpty else { return "Review this reminder" }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}
