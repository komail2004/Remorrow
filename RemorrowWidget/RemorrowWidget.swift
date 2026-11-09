import SwiftUI
import WidgetKit

private struct Digest: Codable {
    var overdue: Int
    var today: Int
    var soon: Int
    var nextTitle: String?
    var nextDueAt: Date?
    var updatedAt: Date

    static var empty: Digest {
        Digest(overdue: 0, today: 0, soon: 0, nextTitle: nil, nextDueAt: nil, updatedAt: .now)
    }
}

private struct DigestEntry: TimelineEntry {
    let date: Date
    let digest: Digest
}

private struct RemorrowProvider: TimelineProvider {
    func placeholder(in context: Context) -> DigestEntry {
        DigestEntry(date: .now, digest: Digest(overdue: 0, today: 2, soon: 4,
             nextTitle: nil, nextDueAt: nil, updatedAt: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (DigestEntry) -> Void) {
        completion(DigestEntry(date: .now, digest: read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DigestEntry>) -> Void) {
        let now = Date()
        let entry = DigestEntry(date: now, digest: read())
        completion(Timeline(entries: [entry],
                            policy: .after(now.addingTimeInterval(30 * 60))))
    }

    private func read() -> Digest {
        guard let defaults = UserDefaults(suiteName: "group.com.komail.Remorrow"),
              let value = defaults.data(forKey: "widgetDigestV1"),
              let digest = try? JSONDecoder().decode(Digest.self, from: value) else {
            return .empty
        }
        return digest
    }
}

private struct DashboardWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DigestEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "hourglass")
                    .font(.caption.weight(.bold))
                Text("remorrow")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(0.96))

            Spacer(minLength: 0)
            Text(entry.digest.overdue > 0 ? "Catch up today" :
                 entry.digest.today > 0 ? "On your radar" : "All clear")
                .font(.system(family == .systemSmall ? .headline : .title3,
                              design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            if family == .systemMedium,
               let title = entry.digest.nextTitle,
               !title.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "calendar")
                    Text(title).lineLimit(1)
                    if let date = entry.digest.nextDueAt {
                        Spacer(minLength: 0)
                        Text(date, style: .time).lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            }

            HStack(spacing: 12) {
                metric(entry.digest.today, "Today")
                metric(entry.digest.soon, "This week")
                if family == .systemMedium {
                    metric(entry.digest.overdue, "Overdue")
                }
                Spacer(minLength: 0)
            }
        }
        .padding(3)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [
                Color(red: 0.02, green: 0.39, blue: 0.66),
                Color(red: 0.0, green: 0.15, blue: 0.34)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func metric(_ count: Int, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(String(count))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(caption).font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
        }
    }
}

struct RemorrowDashboardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.komail.Remorrow.today",
                            provider: RemorrowProvider()) { entry in
            DashboardWidgetView(entry: entry)
        }
        .configurationDisplayName("Remorrow Today")
        .description("Your private daily priorities and what's coming up.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct RemorrowWidgetBundle: WidgetBundle {
    var body: some Widget { RemorrowDashboardWidget() }
}
