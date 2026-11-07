import Foundation

/// Offline baseline, not a semantic AI model; every result requires review.
struct LocalRulesEngine: ExtractionEngine {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: nsRange)
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text), let date = match.date else { return nil }
            let evidence = String(text[range])
            return ActionProposal(
                kind: .reminder,
                title: String(text.prefix(100)),
                sourceEvidence: evidence,
                proposedDate: date,
                uncertaintyFlags: ["confirmDate", "confirmActionType", "confirmTimeZone"],
                origin: .localRules
            )
        }
    }
}
