import Foundation

/// A calendar interval from an authorized local EventKit calendar. Never claims
/// that other people, rooms, or locations are available.
struct ResolveBusyInterval {
    let start: Date
    let end: Date
}

struct ResolveSuggestion: Identifiable, Equatable {
    let start: Date
    let duration: TimeInterval
    var id: TimeInterval { start.timeIntervalSince1970 }
    var end: Date { start.addingTimeInterval(duration) }
}

/// Deterministic scheduling: candidate times are REAL free/busy checks over
/// authorized calendars, never fabricated by a generative model.
enum ResolveSlotPlanner {
    static func isFree(start: Date, duration: TimeInterval,
                       busy: [ResolveBusyInterval],
                       buffer: TimeInterval = 15 * 60) -> Bool {
        guard duration >= 15 * 60, duration <= 12 * 3600 else { return false }
        let end = start.addingTimeInterval(duration)
        return !busy.contains {
            start < $0.end.addingTimeInterval(buffer) &&
            end > $0.start.addingTimeInterval(-buffer)
        }
    }

    static func suggestions(
        around preferred: Date,
        duration: TimeInterval,
        busy: [ResolveBusyInterval],
        now: Date = .now,
        calendar: Calendar = .current,
        maxResults: Int = 3
    ) -> [ResolveSuggestion] {
        guard duration >= 15 * 60, duration <= 8 * 3600,
              maxResults > 0 else { return [] }

        let firstDay = calendar.startOfDay(for: max(preferred, now))
        let earliest = now.addingTimeInterval(30 * 60)
        var possibilities: [ResolveSuggestion] = []

        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay),
                  let closing = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day)
            else { continue }
            for hour in 8...20 {
                for minute in [0, 30] {
                    guard let date = calendar.date(bySettingHour: hour, minute: minute,
                                                    second: 0, of: day),
                          date >= earliest,
                          date.addingTimeInterval(duration) <= closing,
                          isFree(start: date, duration: duration, busy: busy)
                    else { continue }
                    possibilities.append(ResolveSuggestion(start: date, duration: duration))
                }
            }
        }

        possibilities.sort {
            // Avoid presenting three near-identical times. Nearest slots are
            // still ranked first, with a modest preference for original day.
            let a = abs($0.start.timeIntervalSince(preferred))
            let b = abs($1.start.timeIntervalSince(preferred))
            if a != b { return a < b }
            return $0.start < $1.start
        }

        var chosen: [ResolveSuggestion] = []
        for slot in possibilities {
            // The three options must offer meaningful alternatives.
            guard !chosen.contains(where: {
                abs($0.start.timeIntervalSince(slot.start)) < 90 * 60
            }) else { continue }
            chosen.append(slot)
            if chosen.count == min(maxResults, 3) { break }
        }
        return chosen
    }
}
