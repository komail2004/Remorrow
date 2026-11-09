import SwiftUI

struct DailyBriefingCard: View {
    let briefing: DailyBriefing
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("YOUR DAILY BRIEFING", systemImage: "sun.max")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(RemorrowStyle.violet)
                Spacer()
                Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }
            Text(briefing.headline)
                .font(.system(size: 21, weight: .bold, design: .rounded))
            HStack(spacing: 10) {
                countPill(briefing.overdue.count, "Overdue", color: .orange)
                countPill(briefing.today.count, "Today", color: RemorrowStyle.violet)
                countPill(briefing.soon.count, "Next 7 days", color: RemorrowStyle.deepBlue)
            }
            let urgent = Array((briefing.overdue + briefing.today).prefix(3))
            if !urgent.isEmpty {
                Divider()
                ForEach(urgent) { entry in
                    HStack(spacing: 10) {
                        Image(systemName: entry.kind == "subscription" ? "arrow.clockwise"
                              : (entry.kind == "return" ? "shippingbox" :
                                 (entry.kind == "warranty" ? "checkmark.shield" : "checkmark.circle")))
                            .foregroundStyle(RemorrowStyle.violet)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                            Text(entry.dueAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(entry.dueAt < .now ? .orange : RemorrowStyle.secondaryText)
                        }
                        Spacer()
                    }
                }
            }
            Text("Based on items you deliberately saved in Remorrow.")
                .font(.caption2)
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 21))
    }

    private func countPill(_ count: Int, _ label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(count)).font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label).font(.system(size: 10, weight: .medium))
                .foregroundStyle(RemorrowStyle.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RemorrowStyle.canvas, in: RoundedRectangle(cornerRadius: 13))
    }
}
