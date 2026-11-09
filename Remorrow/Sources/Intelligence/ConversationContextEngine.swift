import Foundation

/// Robust local fallback on devices without Apple Foundation Models.
/// The model never assumes the user owns someone else's commitment.
struct ConversationContextEngine: ExtractionEngine {
    private let dated = LocalRulesEngine()

    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        var results = try await dated.extract(from: input)
        let segments = LocalRulesEngine.segments(from: input.text)
        for phrase in segments {
            let message = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = message.lowercased()
            guard message.count >= 10 else { continue }
            // Only obvious first-person commitments, not "you should" or
            // text from unknown speakers that looks like a question.
            let explicitSelf = ["i'll ", "i will ", "i need to ", "i have to ",
                                "remind me to ", "don't let me forget to "]
                .contains { lower.hasPrefix($0) }
            guard explicitSelf && !lower.contains("?") else { continue }
            // If this sentence already produced an accurate dated candidate,
            // it doesn't need another undated duplicate.
            guard !results.contains(where: { message.localizedCaseInsensitiveContains($0.sourceEvidence) ||
                $0.sourceEvidence.localizedCaseInsensitiveContains(message) }) else { continue }
            let title = SmartTitleGenerator.title(from: message)
            guard title.count >= 5 else { continue }
            results.append(ActionProposal(
                kind: .reminder,
                title: title,
                sourceEvidence: message,
                proposedDate: nil,
                uncertaintyFlags: ["missingDate", "confirmResponsibility", "confirmActionType"],
                origin: .localRules
            ))
        }
        return Array(results.prefix(12))
    }
}

/// Uses Apple's private on-device language model only when the SDK, OS, model,
/// language, and device make it available. No remote inference is used.
struct SmartExtractionPipeline: ExtractionEngine {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        let baseline = ConversationContextEngine()
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return try await ExtractionRouter(
                preferred: AppleOnDeviceExtractionEngine(),
                fallback: baseline
            ).extract(from: input)
        }
        #endif
        return try await baseline.extract(from: input)
    }
}
