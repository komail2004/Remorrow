import SwiftUI
import SwiftData

/// One searchable, entirely local index over user-confirmed records.
struct MemorySearchView: View {
    @Query(sort: \SavedAction.dueAt) private var plans: [SavedAction]
    @Query(sort: \ReturnItem.createdAt, order: .reverse) private var receipts: [ReturnItem]
    @Query(sort: \SubscriptionItem.createdAt, order: .reverse) private var subscriptions: [SubscriptionItem]

    let onDeletePlan: @MainActor (SavedAction) async -> Bool
    let onOpenFinance: () -> Void

    @State private var query = ""
    @State private var filter = "All"
    private let categories = ["All", "Plans", "Receipts", "Subscriptions"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Find anything.")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("Search your saved notes, receipts, orders, and renewal details. Everything stays on-device.")
                    .font(.subheadline)
                    .foregroundStyle(RemorrowStyle.secondaryText)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RemorrowStyle.secondaryText)
                    TextField("Search saved memories", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("memorySearchField")
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(14)
                .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 16))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) { filter = category }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(filter == category ? RemorrowStyle.primaryAction : RemorrowStyle.surface,
                                            in: Capsule())
                                .foregroundStyle(filter == category ? .white : RemorrowStyle.primaryText)
                        }
                    }
                }

                if resultCount == 0 {
                    RemorrowCard {
                        Label(query.isEmpty ? "Your captured memories will appear here." : "No saved matches. Try different words.",
                              systemImage: "text.magnifyingglass")
                            .font(.subheadline)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }
                }

                if filter == "All" || filter == "Plans" {
                    ForEach(matchedPlans) { item in
                        NavigationLink {
                            SavedActionDetailsView(action: item) {
                                await onDeletePlan(item)
                            }
                        } label: {
                            resultRow(symbol: item.kind == "calendarEvent" ? "calendar" : "checkmark.circle",
                                      title: item.title, subtitle: item.dueAt.formatted(date: .abbreviated, time: .shortened),
                                      caption: "PLAN", imageName: item.attachmentName)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if filter == "All" || filter == "Receipts" {
                    ForEach(matchedReceipts) { item in
                        NavigationLink {
                            CapturedMemoryView(title: item.itemName, subtitle: item.merchant,
                                               category: "RECEIPT",
                                               dateLabel: item.hasConfirmedReturnDeadline ? "Return by" : "Saved",
                                               date: item.hasConfirmedReturnDeadline ? item.deadline : item.createdAt,
                                               sourceText: item.sourceText,
                                               imageName: item.attachmentName,
                                               otherDetail: item.warrantyExpiresAt.map { "Warranty expires: " + $0.formatted(date: .abbreviated, time: .omitted) },
                                               onOpenFinance: onOpenFinance)
                        } label: {
                            resultRow(symbol: "receipt", title: item.itemName,
                                      subtitle: item.merchant, caption: "RECEIPT",
                                      imageName: item.attachmentName)
                        }.buttonStyle(.plain)
                    }
                }
                if filter == "All" || filter == "Subscriptions" {
                    ForEach(matchedSubscriptions) { item in
                        NavigationLink {
                            CapturedMemoryView(title: item.name, subtitle: item.merchant,
                                               category: "SUBSCRIPTION",
                                               dateLabel: "Next charge", date: item.nextCharge,
                                               sourceText: item.sourceText,
                                               imageName: item.attachmentName,
                                               otherDetail: item.amount.map { String(format: "Estimated $%.2f · %@", $0, item.frequency) },
                                               onOpenFinance: onOpenFinance)
                        } label: {
                            resultRow(symbol: "arrow.clockwise", title: item.name,
                                      subtitle: item.merchant, caption: "SUBSCRIPTION",
                                      imageName: item.attachmentName)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(22)
        }
        .background(RemorrowStyle.canvas.ignoresSafeArea())
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var matchedPlans: [SavedAction] {
        plans.filter {
            SearchRanking.score(query, fields: [$0.title, $0.sourceText ?? "", $0.kind,
                                                "reminder reminders calendar event events plan plans"]) > 0
            && SearchRanking.matchesDate(query, date: $0.dueAt)
        }.sorted {
            SearchRanking.score(query, fields: [$0.title, $0.sourceText ?? ""]) >
            SearchRanking.score(query, fields: [$1.title, $1.sourceText ?? ""])
        }
    }
    private var matchedReceipts: [ReturnItem] {
        receipts.filter {
            SearchRanking.score(query, fields: [$0.itemName, $0.merchant,
                                               $0.receiptNumber ?? "", $0.sourceText ?? "",
                                               "receipt receipts purchase order invoice"]) > 0
            && SearchRanking.matchesDate(query,
                 date: $0.hasConfirmedReturnDeadline ? $0.deadline : ($0.warrantyExpiresAt ?? $0.createdAt))
        }
    }
    private var matchedSubscriptions: [SubscriptionItem] {
        subscriptions.filter {
            SearchRanking.score(query, fields: [$0.name, $0.merchant, $0.sourceText ?? "",
                                                "subscription subscriptions renew renewal recurring billing"]) > 0
            && SearchRanking.matchesDate(query, date: $0.nextCharge)
        }
    }
    private var resultCount: Int {
        (filter == "All" || filter == "Plans" ? matchedPlans.count : 0)
        + (filter == "All" || filter == "Receipts" ? matchedReceipts.count : 0)
        + (filter == "All" || filter == "Subscriptions" ? matchedSubscriptions.count : 0)
    }

    private func resultRow(symbol: String, title: String, subtitle: String,
                           caption: String, imageName: String?) -> some View {
        HStack(spacing: 12) {
            if let img = CaptureMediaStore.image(named: imageName) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 55, height: 57).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(RemorrowStyle.violet)
                    .frame(width: 55, height: 57)
                    .background(RemorrowStyle.blueTint, in: RoundedRectangle(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(caption).font(.system(size: 10, weight: .bold))
                    .tracking(1).foregroundStyle(RemorrowStyle.violet)
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(RemorrowStyle.primaryText).lineLimit(2)
                Text(subtitle).font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption)
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
        .padding(12)
        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 17))
    }
}

enum SearchRanking {
    private static let ignored: Set<String> = [
        "where", "is", "are", "my", "me", "show", "find", "what",
        "which", "can", "you", "please", "the", "a", "an",
        "with", "for", "from", "that", "this", "month", "week",
        "on", "in", "of", "do", "i", "have", "saved", "all", "and"
    ]

    static func score(_ query: String, fields: [String]) -> Int {
        let words = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !ignored.contains($0) }
        if words.isEmpty { return 1 }
        let lower = fields.map { $0.lowercased() }
        guard words.allSatisfy({ word in lower.contains(where: { $0.contains(word) }) }) else { return 0 }
        return words.reduce(0) { total, word in
            total + lower.enumerated().reduce(0) { rank, entry in
                rank + (entry.element.contains(word) ? max(1, 8 - entry.offset * 2) : 0)
            }
        }
    }

    static func matchesDate(_ query: String, date: Date, now: Date = .now,
                            calendar: Calendar = .current) -> Bool {
        let q = query.lowercased()
        if q.contains("this month") {
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }
        if q.contains("next month"),
           let shifted = calendar.date(byAdding: .month, value: 1, to: now) {
            return calendar.isDate(date, equalTo: shifted, toGranularity: .month)
        }
        if q.contains("this week") {
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        }
        if q.contains("next week"),
           let shifted = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
            return calendar.isDate(date, equalTo: shifted, toGranularity: .weekOfYear)
        }
        return true
    }
}

private struct CapturedMemoryView: View {
    let title: String
    let subtitle: String
    let category: String
    let dateLabel: String
    let date: Date
    let sourceText: String?
    let imageName: String?
    let otherDetail: String?
    let onOpenFinance: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionEyebrow(title: category)
                Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
                Text(subtitle).foregroundStyle(RemorrowStyle.secondaryText)
                if let image = CaptureMediaStore.image(named: imageName) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                RemorrowCard {
                    VStack(alignment: .leading, spacing: 9) {
                        SectionEyebrow(title: dateLabel)
                        Text(date.formatted(date: .complete, time: .shortened))
                            .font(.headline)
                        if let otherDetail { Text(otherDetail).font(.subheadline) }
                    }
                }
                if let sourceText, !sourceText.isEmpty {
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 7) {
                            SectionEyebrow(title: "SOURCE")
                            Text(sourceText).font(.subheadline).textSelection(.enabled)
                        }
                    }
                }
                Button("Manage in Receipts & Subscriptions") { onOpenFinance() }
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(22)
        }
        .background(RemorrowStyle.canvas.ignoresSafeArea())
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
    }
}
