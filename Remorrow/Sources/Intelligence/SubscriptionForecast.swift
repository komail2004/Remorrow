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
        return "Every \\(interval) \\(singular)s"
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
