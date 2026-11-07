import Foundation

/// MVP baseline: recognizes date candidates using Foundation.
/// This is deliberately conservative, and not a general NLP engine.
struct LocalRulesEngine: ExtractionEngine {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        let trimmed = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        let matches = detector.matches(in: trimmed, options: [], range: nsRange)
        return matches.compactMap { match -> ActionProposal? in
            guard let range = Range(match.range, in: trimmed) else { return nil }
            let evidence = String(trimmed[range])
            return ActionProposal(
                kind: .reminder,
                title: String(trimmed.prefix(120)),
                sourceEvidence: evidence,
                proposedDate: match.date,
                uncertaintyFlags: ["confirmDate", "confirmActionType", "confirmTimeZone"],
                origin: .localRules
            )
        }
    }
}
