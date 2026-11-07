import Foundation

struct ExtractionInput: Sendable {
    let text: String
    let capturedAt: Date
    let localeIdentifier: String
    let timeZoneIdentifier: String
}

enum ExtractionEngineError: Error {
    case unavailable
    case unsupportedInput
    case invalidOutput
}

protocol ExtractionEngine: Sendable {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal]
}

/// Orchestrates compatible engines. All output remains a suggestion and
/// requires explicit user review before any system write.
struct ExtractionRouter: ExtractionEngine {
    let preferred: (any ExtractionEngine)?
    let fallback: any ExtractionEngine

    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        if let preferred {
            do {
                let result = try await preferred.extract(from: input)
                if !result.isEmpty { return result }
            } catch {
                // Falling back is intentional; never interpret engine failure
                // as permission to create an event.
            }
        }
        return try await fallback.extract(from: input)
    }
}
