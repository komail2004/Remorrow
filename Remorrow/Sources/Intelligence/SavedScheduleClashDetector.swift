import Foundation

struct SavedScheduleClash: Identifiable {
    let first: SavedPlanRecord
    let second: SavedPlanRecord
    var id: String {
        [first.id.uuidString, second.id.uuidString].sorted().joined(separator: ":")
    }
}

/// Simple discovery for existing Remorrow-created Calendar events.
/// The app currently creates one-hour events; the interactive resolver reads
/// the REAL duration and free/busy data from EventKit before proposing a move.
enum SavedScheduleClashDetector {
    static func find(_ records: [SavedPlanRecord],
                     now: Date = .now) -> [SavedScheduleClash] {
        let events = records.filter {
            $0.kind == "calendarEvent" &&
            $0.dueAt >= now.addingTimeInterval(-2*86400)
        }.sorted { $0.dueAt < $1.dueAt }
        var clashes: [SavedScheduleClash] = []
        for i in events.indices {
            for j in events.indices where j > i {
                let a = events[i]
                let b = events[j]
                if b.dueAt.timeIntervalSince(a.dueAt) >= 3600 { break }
                clashes.append(SavedScheduleClash(first: a, second: b))
            }
        }
        return clashes
    }
}
