import Foundation

/// Future charge dates are projections from a user-confirmed anchor, not merchant transactions.
enum SubscriptionForecast {
    static func dates(from verified: Date, frequency: String, intervalCount: Int = 1,
                      count: Int = 6, calendar: Calendar = .current) -> [Date] {
        guard count > 0 else { return [] }
        let component: Calendar.Component
        switch frequency.lowercased() {
        case "daily": component = .day
        case "weekly": component = .weekOfYear
        case "monthly": component = .month
        case "yearly": component = .year
        default: return [verified]
        }
        let interval = max(1, min(365, intervalCount))
        // Always calculate from the original date so Jan 31 -> Feb 28 -> Mar 31,
        // rather than drifting from the shortened February date.
        return (0..<min(count, 24)).compactMap {
            calendar.date(byAdding: component, value: $0 * interval, to: verified)
        }
    }


    /// A verified next charge is an anchor. Later renewal dates are only estimates.
    struct Occurrence: Equatable {
        let date: Date
        let isProjected: Bool
    }

    /// Keeps ongoing plans useful when the originally verified charge date passes,
    /// without rewriting that confirmed date or asserting a merchant actually billed.
    static func upcomingOccurrences(from verified: Date, frequency: String,
                                    intervalCount: Int = 1, count: Int = 3,
                                    after now: Date = .now,
                                    calendar: Calendar = .current) -> [Occurrence] {
        guard count > 0 else { return [] }
        let count = min(count, 8)
        if verified > now {
            return dates(from: verified, frequency: frequency, intervalCount: intervalCount,
                         count: count, calendar: calendar).enumerated().map {
                Occurrence(date: $0.element, isProjected: $0.offset > 0)
            }
        }
        let component: Calendar.Component
        switch frequency.lowercased() {
        case "daily": component = .day
        case "weekly": component = .weekOfYear
        case "monthly": component = .month
        case "yearly": component = .year
        default: return [] // No invented renewals for "Other".
        }
        let interval = max(1, min(365, intervalCount))
        let difference = calendar.dateComponents([component], from: verified, to: now)
        let elapsed: Int
        switch component {
        case .day: elapsed = difference.day ?? 0
        case .weekOfYear: elapsed = difference.weekOfYear ?? 0
        case .month: elapsed = difference.month ?? 0
        case .year: elapsed = difference.year ?? 0
        default: elapsed = 0
        }
        // Starting one cycle early handles month ends and daylight saving changes.
        let first = max(1, elapsed / interval - 1)
        var results: [Occurrence] = []
        for cycle in first..<(first + count + 8) {
            guard let date = calendar.date(byAdding: component,
                                           value: cycle * interval, to: verified) else { continue }
            if date > now {
                results.append(Occurrence(date: date, isProjected: true))
                if results.count == count { break }
            }
        }
        return results
    }

    static func monthlyEquivalent(amount: Double, frequency: String,
                                  intervalCount: Int = 1) -> Double? {
        guard amount.isFinite, amount >= 0 else { return nil }
        let interval = Double(max(1, min(365, intervalCount)))
        switch frequency.lowercased() {
        case "daily": return amount * 365.2425 / 12.0 / interval
        case "weekly": return amount * 52.0 / 12.0 / interval
        case "monthly": return amount / interval
        case "yearly": return amount / 12.0 / interval
        default: return nil
        }
    }

    static func cadenceDescription(frequency: String, intervalCount: Int) -> String {
        let interval = max(1, min(365, intervalCount))
        if frequency.lowercased() == "other" { return "Custom / unknown" }
        if interval == 1 { return frequency.capitalized }
        let singular: String
        switch frequency.lowercased() {
        case "daily": singular = "day"
        case "weekly": singular = "week"
        case "monthly": singular = "month"
        case "yearly": singular = "year"
        default: return "Custom / unknown"
        }
        return "Every \(interval) \(singular)s"
    }

    static func monthlyTotalsByCurrency(_ items: [SubscriptionItem]) -> [String: Double] {
        items.reduce(into: [String: Double]()) { totals, item in
            guard item.isActive, let amount = item.amount,
                  let equivalent = monthlyEquivalent(
                      amount: amount, frequency: item.frequency,
                      intervalCount: item.effectiveBillingInterval
                  ) else { return }
            totals[item.effectiveCurrencyCode, default: 0] += equivalent
        }
    }

    /// Legacy single-currency convenience used by existing callers.
    /// UI must use monthlyTotalsByCurrency to avoid mixing currencies.
    static func estimatedMonthlyTotal(_ items: [SubscriptionItem]) -> Double {
        monthlyTotalsByCurrency(items)["USD"] ?? 0
    }
}
