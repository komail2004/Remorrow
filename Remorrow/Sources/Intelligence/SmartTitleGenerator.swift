import Foundation

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
        let prefixes = [
            #"(?i)^(?:hey|hi|hello)[!,.:\s]+"#,
            #"(?i)^(?:please\s+)?(?:can|could|would)\s+you\s+(?:please\s+)?(?:remind\s+me\s+to\s+|remember\s+to\s+)?"#,
            #"(?i)^(?:please\s+)?(?:remind\s+me\s+to|remember\s+to|don't\s+forget\s+to|note\s+to|reminder\s*[:\-]|todo\s*[:\-]|task\s*[:\-])\s*"#,
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
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",.;:!?-–")))
        // Removing a date often leaves a dangling "on", "by", or "at".
        result = result.replacingOccurrences(of: #"(?i)\\s+(?:on|at|by|before|around|for)$"#,
                                             with: "", options: .regularExpression)
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
