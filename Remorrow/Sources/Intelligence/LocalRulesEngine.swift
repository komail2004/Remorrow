import Foundation
import NaturalLanguage

/// Offline baseline, not a semantic AI model; every result requires review.
struct LocalRulesEngine: ExtractionEngine {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: nsRange)
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        let sentences = tokenizer.tokens(for: text.startIndex..<text.endIndex)
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text), let date = match.date else { return nil }
            let evidence = String(text[range])
            let sentence = sentences.first(where: { $0.overlaps(range) })
                .map { String(text[$0]) } ?? text
            return ActionProposal(
                kind: Self.suggestedKind(for: sentence),
                title: SmartTitleGenerator.title(from: sentence, dateEvidence: evidence),
                sourceEvidence: evidence,
                proposedDate: date,
                uncertaintyFlags: ["confirmDate", "confirmActionType", "confirmTimeZone"],
                origin: .localRules
            )
        }
    }
    private static func suggestedKind(for sentence: String) -> ProposedActionKind {
        let text = sentence.lowercased()
        let reminders = ["remind me", "remember to", "don't forget", "submit", "finish",
                         "pay", "buy", "send", "return", "cancel", "prepare"]
        if reminders.contains(where: { text.contains($0) }) { return .reminder }
        let events = ["meeting", "meet with", "dinner", "lunch", "appointment",
                      "concert", "interview", "flight", "party", "reservation"]
        if events.contains(where: { text.contains($0) }) { return .calendarEvent }
        return .reminder
    }
}
