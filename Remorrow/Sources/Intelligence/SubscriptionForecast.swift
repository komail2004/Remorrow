import Foundation

/// Forward projections from a user-verified charge date and cadence.
/// NOT confirmation of future merchant charges, and not transaction history.
enum SubscriptionForecast {
    static func dates(from verified: Date, frequency: String, count: Int = 6,
                      calendar: Calendar = .current) -> [Date] {
        guard count > 0 else { return [] }
        let component: Calendar.Component
        switch frequency.lowercased() {
        case "weekly": component = .weekOfYear
        case "monthly": component = .month
        case "yearly": component = .year
        default: return [verified]
        }
        return (0..<min(count, 24)).compactMap {
            calendar.date(byAdding: component, value: $0, to: verified)
        }
    }

    static func monthlyEquivalent(amount: Double, frequency: String) -> Double? {
        guard amount.isFinite, amount >= 0 else { return nil }
        switch frequency.lowercased() {
        case "weekly": return amount * 52.0 / 12.0
        case "monthly": return amount
        case "yearly": return amount / 12.0
        default: return nil
        }
    }

    static func estimatedMonthlyTotal(_ items: [SubscriptionItem]) -> Double {
        items.filter { $0.isActive }.compactMap {
            guard let amount = $0.amount else { return nil }
            return monthlyEquivalent(amount: amount, frequency: $0.frequency)
        }.reduce(0,+)
    }
}
