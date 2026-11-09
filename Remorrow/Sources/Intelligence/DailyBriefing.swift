import Foundation

struct BriefingEntry: Identifiable {
    let id: String
    let title: String
    let dueAt: Date
    let kind: String
}

struct DailyBriefing {
    let overdue: [BriefingEntry]
    let today: [BriefingEntry]
    let soon: [BriefingEntry]
    var urgentCount: Int { overdue.count + today.count }
    var headline: String {
        if !overdue.isEmpty { return "Catch up on " + String(overdue.count) + " overdue item" + (overdue.count == 1 ? "" : "s") }
        if !today.isEmpty { return String(today.count) + " thing" + (today.count == 1 ? "" : "s") + " on today's radar" }
        return soon.isEmpty ? "Nothing urgent today." : "You're ahead of the day."
    }

    static func build(items: [BriefingEntry], now: Date = .now, calendar: Calendar = .current) -> DailyBriefing {
        let dayStart = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now.addingTimeInterval(86400)
        let horizon = calendar.date(byAdding: .day, value: 7, to: tomorrow) ?? tomorrow.addingTimeInterval(7 * 86400)
        let sorted = items.sorted { $0.dueAt < $1.dueAt }
        return DailyBriefing(
            overdue: sorted.filter { $0.dueAt < now },
            today: sorted.filter { $0.dueAt >= now && $0.dueAt < tomorrow },
            soon: sorted.filter { $0.dueAt >= tomorrow && $0.dueAt < horizon }
        )
    }
}
