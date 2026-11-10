import Foundation

/// A conservative, explainable, on-device check against plans Remorrow already
/// saved. It never edits, deletes, or prevents a deliberate conflicting plan.
struct SavedPlanRecord: Identifiable {
    let id: UUID
    let title: String
    let dueAt: Date
    let kind: String
    /// Optional EventKit ID for records from SwiftData. Not available in
    /// synthetic unit-test fixtures and must never be fabricated.
    let externalID: String?

    init(id: UUID, title: String, dueAt: Date, kind: String,
         externalID: String? = nil) {
        self.id = id
        self.title = title
        self.dueAt = dueAt
        self.kind = kind
        self.externalID = externalID
    }
}

struct PlanConflict: Identifiable {
    enum Reason: Equatable {
        case likelyDuplicate
        case samePlanDifferentTime
        case overlappingEvent
    }

    let record: SavedPlanRecord
    let reason: Reason

    var id: UUID { record.id }
    var isSamePlan: Bool { reason != .overlappingEvent }
}

struct PlanDuplicatePair: Identifiable {
    let original: SavedPlanRecord
    let possibleExtra: SavedPlanRecord
    let reason: PlanConflict.Reason

    var id: UUID { possibleExtra.id }
}

enum PlanConflictDetector {
    /// Records must be supplied in their original creation order. Each extra
    /// gets one suggested original, so three duplicates result in two review
    /// rows instead of a noisy all-pairs comparison.
    static func existingDuplicates(in creationOrder: [SavedPlanRecord],
                                   calendar: Calendar = .current) -> [PlanDuplicatePair] {
        var previous: [SavedPlanRecord] = []
        var result: [PlanDuplicatePair] = []
        for item in creationOrder {
            if let likelyMatch = find(title: item.title, dueAt: item.dueAt,
                                      kind: item.kind, among: previous,
                                      calendar: calendar).first(where: { $0.isSamePlan }) {
                result.append(PlanDuplicatePair(
                    original: likelyMatch.record,
                    possibleExtra: item,
                    reason: likelyMatch.reason
                ))
            }
            previous.append(item)
        }
        return result
    }

    /// Do not infer that two plans are identical merely because they share a
    /// time slot. Equally, a similar name on different days is not automatically
    /// a duplicate: it might be a legitimate recurring activity.
    static func find(
        title: String,
        dueAt: Date,
        kind: String,
        among records: [SavedPlanRecord],
        calendar: Calendar = .current
    ) -> [PlanConflict] {
        let newIdentity = identity(title)
        return records.compactMap { previous -> PlanConflict? in
            guard previous.kind == kind else { return nil }

            let timeDifference = abs(previous.dueAt.timeIntervalSince(dueAt))
            let sameDay = calendar.isDate(previous.dueAt, inSameDayAs: dueAt)
            if sameDay && sameMeaning(newIdentity, identity(previous.title)) {
                return PlanConflict(
                    record: previous,
                    reason: timeDifference <= 5 * 60 ? .likelyDuplicate : .samePlanDifferentTime
                )
            }

            // A slot conflict is not the same as an event duplicate.
            // Reminders are often legitimately due together.
            if kind == "calendarEvent" && timeDifference < 60 * 60 {
                return PlanConflict(record: previous, reason: .overlappingEvent)
            }
            return nil
        }
        .sorted {
            if $0.isSamePlan != $1.isSamePlan { return $0.isSamePlan }
            if $0.reason != $1.reason {
                return $0.reason == .likelyDuplicate
            }
            return abs($0.record.dueAt.timeIntervalSince(dueAt))
                < abs($1.record.dueAt.timeIntervalSince(dueAt))
        }
    }

    private struct Identity {
        let category: String?
        let meaningfulWords: Set<String>
        let normalizedWords: Set<String>
    }

    private static let common: Set<String> = [
        "a", "an", "the", "i", "me", "my", "mine", "you", "your", "yours",
        "we", "us", "our", "ours", "he", "him", "she", "her", "they", "them",
        "it", "its", "with", "at", "in", "on", "for", "from", "to",
        "of", "by", "and", "or", "will", "would", "should", "could",
        "have", "has", "had", "be", "is", "are", "am", "was", "were",
        "going", "gonna", "having", "grabbing", "eating", "coming", "over",
        "together", "do", "does", "did", "let", "lets", "get", "got",
        "need", "needs", "want", "wants", "plan", "plans", "planning",
        "reminder", "remind", "remember", "event", "scheduled",
        "today", "tomorrow", "yesterday", "next", "this", "last",
        "morning", "afternoon", "evening", "night", "noon",
        "monday", "tuesday", "wednesday", "thursday", "friday",
        "saturday", "sunday", "january", "february", "march", "april",
        "may", "june", "july", "august", "september", "october",
        "november", "december", "pm", "am", "oclock"
    ]

    private static let groupings: [(String, Set<String>)] = [
        ("dinner", ["dinner", "supper", "dine", "dining"]),
        ("lunch", ["lunch", "brunch"]),
        ("breakfast", ["breakfast"]),
        ("meeting", ["meeting", "meet", "meetup", "catchup"]),
        ("presentation", ["presentation", "presenting", "present"]),
        ("interview", ["interview"]),
        ("appointment", ["appointment"]),
        ("exam", ["exam", "test"]),
        ("assignment", ["assignment", "homework", "essay", "paper"]),
        ("flight", ["flight", "flying"]),
        ("purchase", ["buy", "purchase", "shopping"]),
        ("payment", ["pay", "payment", "bill"]),
        ("return", ["return", "refund"])
    ]

    private static func identity(_ original: String) -> Identity {
        let normalized = original.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                          locale: Locale(identifier: "en_US"))
            .lowercased()
        let words = normalized.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { word -> String in
                // Common spelling variations should not duplicate a person's
                // event. All spelling aliases are kept conservative.
                switch word {
                case "ruby", "rubi": return "rubi"
                default: return word
                }
            }
        let all = Set(words.filter {
            Int($0) == nil &&
            $0.range(of: #"^\d{1,2}(?:am|pm)$"#, options: .regularExpression) == nil &&
            $0.range(of: #"^\d{1,2}\d{2}(?:am|pm)$"#, options: .regularExpression) == nil &&
            !common.contains($0)
        })
        let category = groupings.first { !$0.1.isDisjoint(with: all) }?.0
        let core = all.subtracting(groupings.flatMap { $0.1 })
        return Identity(category: category,
                        meaningfulWords: core,
                        normalizedWords: all)
    }

    private static func sameMeaning(_ lhs: Identity, _ rhs: Identity) -> Bool {
        if let l = lhs.category, let r = rhs.category {
            guard l == r else { return false }
            if !lhs.meaningfulWords.isEmpty && !rhs.meaningfulWords.isEmpty {
                // Same activity + same subject/participants, irrespective of
                // word order: "Dinner with Rubi" == "Rubi will have dinner with me".
                return lhs.meaningfulWords == rhs.meaningfulWords
            }
            return lhs.meaningfulWords == rhs.meaningfulWords
        }
        // Titles with no recognized activity need stronger literal agreement.
        guard lhs.category == rhs.category,
              lhs.normalizedWords.count >= 2,
              rhs.normalizedWords.count >= 2 else { return false }
        return lhs.normalizedWords == rhs.normalizedWords
    }
}
