import Foundation

/// Extracts explicit clock times independently from dates. This is deliberately
/// deterministic: a message saying "7 PM" must never turn into the clock time
/// at which the user opened the app.
struct ExplicitClockTime: Equatable, Sendable {
    let hour: Int
    let minute: Int
    let evidence: String
}

enum ExplicitTimeParser {
    private static let meridiemPattern =
        #"(?i)(?<![\p{L}\d])(\d{1,2})(?:[:.]([0-5]\d))?\s*([ap]\.?m\.?)(?![\p{L}\d])"#
    private static let twentyFourHourPattern =
        #"(?i)(?<![\p{L}\d])((?:1[3-9]|2[0-3])):([0-5]\d)(?![\p{L}\d])"#
    private static let namedPattern = #"(?i)\b(noon|midnight)\b"#

    static func parse(in text: String) -> ExplicitClockTime? {
        if let match = first(meridiemPattern, in: text) {
            let ns = text as NSString
            guard let number = Int(ns.substring(with: match.range(at: 1))),
                  (1...12).contains(number) else { return nil }
            let minute = match.range(at: 2).location == NSNotFound
                ? 0 : (Int(ns.substring(with: match.range(at: 2))) ?? 0)
            let suffix = ns.substring(with: match.range(at: 3))
                .lowercased().replacingOccurrences(of: ".", with: "")
            let hour = suffix == "pm" ? (number % 12) + 12 : number % 12
            return ExplicitClockTime(hour: hour, minute: minute,
                                     evidence: ns.substring(with: match.range))
        }

        if let match = first(twentyFourHourPattern, in: text) {
            let ns = text as NSString
            guard let hour = Int(ns.substring(with: match.range(at: 1))),
                  let minute = Int(ns.substring(with: match.range(at: 2))) else {
                return nil
            }
            return ExplicitClockTime(hour: hour, minute: minute,
                                     evidence: ns.substring(with: match.range))
        }

        if let match = first(namedPattern, in: text) {
            let evidence = (text as NSString).substring(with: match.range)
            return ExplicitClockTime(hour: evidence.lowercased() == "noon" ? 12 : 0,
                                     minute: 0, evidence: evidence)
        }
        return nil
    }

    /// When the day is omitted, display the recognized time on a *clearly
    /// unverified* upcoming date in Review. Saving requires date confirmation.
    static func suggestedPickerDate(hour: Int?, minute: Int?,
                                    now: Date = .now,
                                    calendar: Calendar = .current) -> Date {
        guard let hour, (0...23).contains(hour),
              let minute, (0...59).contains(minute) else {
            return now.addingTimeInterval(3600)
        }
        // Preserve the intended wall-clock hour across DST changes. Adding
        // elapsed hours to midnight can turn 7pm into 6pm or 8pm.
        guard let candidate = calendar.date(bySettingHour: hour,
                                            minute: minute, second: 0,
                                            of: now) else {
            return now.addingTimeInterval(3600)
        }
        if candidate >= now { return candidate }
        return calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }


    /// All clock times in chronological source order. Review can distinguish
    /// "moved from 6pm to 7pm" from a single unambiguous time.
    static func all(in text: String) -> [ExplicitClockTime] {
        let ns = text as NSString
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var found: [(position: Int, clock: ExplicitClockTime)] = []
        if let regex = try? NSRegularExpression(pattern: meridiemPattern) {
            for match in regex.matches(in: text, range: fullRange) {
                guard let number = Int(ns.substring(with: match.range(at: 1))),
                      (1...12).contains(number) else { continue }
                let minute = match.range(at: 2).location == NSNotFound
                    ? 0 : (Int(ns.substring(with: match.range(at: 2))) ?? 0)
                let suffix = ns.substring(with: match.range(at: 3))
                    .lowercased().replacingOccurrences(of: ".", with: "")
                let hour = suffix == "pm" ? (number % 12) + 12 : number % 12
                found.append((position: match.range.location,
                              clock: ExplicitClockTime(hour: hour, minute: minute,
                                  evidence: ns.substring(with: match.range))))
            }
        }
        if let regex = try? NSRegularExpression(pattern: twentyFourHourPattern) {
            for match in regex.matches(in: text, range: fullRange) {
                guard let hour = Int(ns.substring(with: match.range(at: 1))),
                      let minute = Int(ns.substring(with: match.range(at: 2))) else {
                    continue
                }
                found.append((position: match.range.location,
                              clock: ExplicitClockTime(hour: hour, minute: minute,
                                  evidence: ns.substring(with: match.range))))
            }
        }
        if let regex = try? NSRegularExpression(pattern: namedPattern) {
            for match in regex.matches(in: text, range: fullRange) {
                let evidence = ns.substring(with: match.range)
                found.append((position: match.range.location,
                              clock: ExplicitClockTime(hour: evidence.lowercased() == "noon" ? 12 : 0,
                                  minute: 0, evidence: evidence)))
            }
        }
        return found.sorted { $0.position < $1.position }.map { $0.clock }
    }

    private static func first(_ pattern: String, in source: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        return regex.firstMatch(in: source,
                                range: NSRange(source.startIndex..<source.endIndex, in: source))
    }
}
