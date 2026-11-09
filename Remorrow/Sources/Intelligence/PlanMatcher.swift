import Foundation

/// Offline potential-match detection. Never modifies a plan; suggestions
/// are displayed to the user alongside the option to create a new plan.
enum PlanMatcher {
    private static let fillers: Set<String> = [
        "the", "a", "an", "my", "our", "to", "at", "on", "for", "with",
        "moved", "changed", "rescheduled", "postponed", "instead",
        "tomorrow", "today", "next", "this", "from", "new", "now",
        "date", "time", "meeting", "reminder", "task"
    ]
    private static func words(_ text: String) -> Set<String> {
        Set(text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !fillers.contains($0) })
    }

    static func looksLikeChange(_ source: String) -> Bool {
        let lower = source.lowercased()
        return ["moved", "rescheduled", "postponed", "changed", "instead",
                "new time", "new date", "now on", "pushed back", "bring forward"]
            .contains { lower.contains($0) }
    }

    static func similar(_ proposed: String, _ existing: String) -> Bool {
        let first = words(proposed)
        let second = words(existing)
        guard !first.isEmpty && !second.isEmpty else { return false }
        let overlap = first.intersection(second).count
        if overlap == 0 { return false }
        let normalizedFirst = proposed.lowercased()
        let normalizedSecond = existing.lowercased()
        if normalizedSecond.count >= 8 && normalizedFirst.contains(normalizedSecond) {
            return true
        }
        // Don't merge unrelated plans that share only one generic word.
        return overlap >= 2 && Double(overlap) / Double(max(first.count, second.count)) >= 0.40
    }

    static func bestMatch(title: String, source: String, kind: String,
                          candidates: [SavedAction], now: Date = .now) -> SavedAction? {
        guard looksLikeChange(source) else { return nil }
        return candidates.first {
            $0.kind == kind &&
            $0.dueAt >= now.addingTimeInterval(-60 * 86400) &&
            similar(title, $0.title)
        }
    }
}
