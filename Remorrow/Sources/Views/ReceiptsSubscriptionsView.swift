import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Two dedicated, fully local workflows: confirmed return deadlines and subscriptions.
struct ReceiptsSubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReturnItem.deadline) private var returns: [ReturnItem]
    @Query(sort: \SubscriptionItem.nextCharge) private var subscriptions: [SubscriptionItem]
    @State private var segment: FinancialDocumentKind = .receipt
    @State private var creating: FinancialDocumentKind?
    @State private var message: String?
    @State private var editingReceipt: ReturnItem?
    @State private var editingSubscription: SubscriptionItem?

    private let returnAlerts = ReturnNotificationScheduler()
    private let renewalAlerts = SubscriptionNotificationScheduler()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("YOUR PURCHASES")
                                .font(.caption.weight(.semibold))
                                .tracking(1.7)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            Text("Receipts &\nsubscriptions")
                                .font(.system(size: 35, weight: .bold, design: .rounded))
                                .foregroundStyle(RemorrowStyle.primaryText)
                        }
                        Spacer()
                        Image(systemName: "creditcard.and.123")
                            .font(.title2.weight(.light))
                            .foregroundStyle(RemorrowStyle.violet)
                    }
                    .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Keep every date in sight.")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Capture a receipt or renewal notice. We'll find the details; you confirm them.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                        HStack(spacing: 11) {
                            heroAction("Scan receipt", icon: "doc.text.viewfinder") { creating = .receipt }
                            heroAction("Add subscription", icon: "arrow.clockwise") { creating = .subscription }
                        }
                        .padding(.top, 8)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [RemorrowStyle.deepBlue, RemorrowStyle.violet],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 24)
                    )

                    Picker("Collection", selection: $segment) {
                        Text("Receipts · \(returns.count)").tag(FinancialDocumentKind.receipt)
                        Text("Subscriptions · \(subscriptions.count)").tag(FinancialDocumentKind.subscription)
                    }
                    .pickerStyle(.segmented)

                    if segment == .subscription && !subscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            SectionEyebrow(title: "PROJECTED MONTHLY SPEND")
                            Text(String(format: "$%.2f", SubscriptionForecast.estimatedMonthlyTotal(subscriptions)))
                                .font(.system(size: 31, weight: .bold, design: .rounded))
                            Text("Estimate from the amount and cadence you entered—not actual bank charges.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                    }

                    HStack {
                        Text(segment == .receipt ? "Your return windows" : "Upcoming charges")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                        Spacer()
                        Button {
                            creating = segment
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                        }
                    }

                    if segment == .receipt {
                        if returns.isEmpty {
                            emptyState("Receipts live here", subtitle: "Photograph or choose a receipt to build your first return reminder.", icon: "receipt")
                        }
                        ForEach(returns) { item in
                            Button {
                                editingReceipt = item
                            } label: {
                                documentRow(title: item.itemName,
                                            detail: item.purchaseAmount.map {
                                                (item.merchant.isEmpty ? "Purchase" : item.merchant) + " · " + String(format: "$%.2f", $0)
                                            } ?? (item.merchant.isEmpty ? "Purchase" : item.merchant),
                                            date: item.deadline,
                                            kind: item.isReturned ? "Returned" : (item.hasConfirmedReturnDeadline ? "Return by" : "Receipt saved"),
                                            attachment: item.attachmentName,
                                            symbol: "shippingbox")
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        if subscriptions.isEmpty {
                            emptyState("Your subscriptions, organized", subtitle: "Scan a renewal notice or enter the next charge date.", icon: "arrow.triangle.2.circlepath")
                        }
                        ForEach(subscriptions) { item in
                            Button {
                                editingSubscription = item
                            } label: {
                                documentRow(title: item.name,
                                            detail: item.amount.map { String(format: "$%.2f · %@", $0, item.frequency) } ?? item.frequency,
                                            date: item.nextCharge,
                                            kind: item.isActive ? "Next charge" : "Paused",
                                            attachment: item.attachmentName,
                                            symbol: "arrow.clockwise")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $creating) { kind in
                FinancialCaptureView(kind: kind) { kind, name, merchant, date, amount, frequency, source, image, hasReturnDeadline, warrantyDate, purchaseDate, receiptNumber in
                    try await create(kind: kind, name: name, merchant: merchant,
                                     date: date, amount: amount, frequency: frequency,
                                     source: source, image: image,
                                     hasReturnDeadline: hasReturnDeadline, warrantyDate: warrantyDate,
                                     purchaseDate: purchaseDate, receiptNumber: receiptNumber)
                }
            }
            .sheet(item: $editingReceipt) { item in
                FinancialDetailsView(
                    name: item.itemName,
                    subtitle: item.merchant,
                    amountLabel: item.purchaseAmount.map { String(format: "Paid $%.2f", $0) },
                    date: item.deadline, dateLabel: item.hasConfirmedReturnDeadline ? "Return deadline" : "No verified return date",
                    forecastDates: [],
                    warrantyDate: item.warrantyExpiresAt, showPrimaryDate: item.hasConfirmedReturnDeadline,
                    purchaseDate: item.purchaseDate, receiptNumber: item.receiptNumber,
                    source: item.sourceText, imageName: item.attachmentName,
                    inactive: item.isReturned, inactiveLabel: "Returned",
                    onToggle: { toggleReturn(item) },
                    onUpdate: { name, merchant, date in updateReturn(item, name: name, merchant: merchant, date: date) },
                    onDelete: { deleteReturn(item) }
                )
            }
            .sheet(item: $editingSubscription) { item in
                FinancialDetailsView(
                    name: item.name, subtitle: item.merchant,
                    amountLabel: item.amount.map { String(format: "$%.2f · %@", $0, item.frequency) },
                    date: item.nextCharge, dateLabel: "Next charge",
                    forecastDates: SubscriptionForecast.dates(from: item.nextCharge, frequency: item.frequency),
                    warrantyDate: nil, showPrimaryDate: true,
                    purchaseDate: nil, receiptNumber: nil,
                    source: item.sourceText, imageName: item.attachmentName,
                    inactive: !item.isActive, inactiveLabel: "Paused",
                    onToggle: { toggleSubscription(item) },
                    onUpdate: { name, merchant, date in updateSubscription(item, name: name, merchant: merchant, date: date) },
                    onDelete: { deleteSubscription(item) }
                )
            }
            .alert("Remorrow", isPresented: Binding(
                get: { message != nil }, set: { if !$0 { message = nil } }
            )) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    private func heroAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 43)
                .foregroundStyle(RemorrowStyle.deepBlue)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func documentRow(title: String, detail: String, date: Date,
                             kind: String, attachment: String?, symbol: String) -> some View {
        HStack(spacing: 13) {
            if let image = CaptureMediaStore.image(named: attachment) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 81)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: symbol)
                    .font(.title2.weight(.light))
                    .foregroundStyle(RemorrowStyle.violet)
                    .frame(width: 72, height: 81)
                    .background(RemorrowStyle.blueTint, in: RoundedRectangle(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(RemorrowStyle.primaryText)
                Text(detail).font(.caption).foregroundStyle(RemorrowStyle.secondaryText)
                Text(kind + " · " + date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RemorrowStyle.violet)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func emptyState(_ title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 33, weight: .light))
                .foregroundStyle(RemorrowStyle.violet)
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(RemorrowStyle.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    @MainActor
    private func create(kind: FinancialDocumentKind, name: String, merchant: String,
                        date: Date, amount: Double?, frequency: String,
                        source: String, image: Data?,
                        hasReturnDeadline: Bool, warrantyDate: Date?,
                        purchaseDate: Date?, receiptNumber: String?) async throws {
        // Make attachment before inserting the model. Nothing is created on OCR alone.
        let filename = try image.map { try CaptureMediaStore.save($0) }
        do {
            if kind == .receipt {
                let item = ReturnItem(itemName: name, merchant: merchant, deadline: date)
                item.purchaseAmount = amount
                item.hasConfirmedReturnDeadline = hasReturnDeadline
                item.warrantyExpiresAt = warrantyDate
                item.purchaseDate = purchaseDate
                item.receiptNumber = receiptNumber
                item.sourceText = source.isEmpty ? nil : source
                item.attachmentName = filename
                modelContext.insert(item)
                try modelContext.save()
                do {
                    let scheduled = try await returnAlerts.schedule(item)
                    if warrantyDate != nil { _ = try? await returnAlerts.scheduleWarranty(item) }
                    message = scheduled ? "Receipt saved and return alert scheduled."
                                        : (warrantyDate != nil ? "Receipt and warranty saved. Check notification permissions for alerts."
                                                               : "Receipt saved. No notification was scheduled.")
                } catch {
                    message = "Receipt saved, but notification scheduling failed."
                }
            } else {
                let item = SubscriptionItem(name: name, merchant: merchant, nextCharge: date,
                                            amount: amount, frequency: frequency,
                                            sourceText: source.isEmpty ? nil : source,
                                            attachmentName: filename)
                modelContext.insert(item)
                try modelContext.save()
                do {
                    let scheduled = try await renewalAlerts.schedule(item)
                    message = scheduled ? "Subscription saved and charge alert scheduled."
                                        : "Subscription saved. No notification was scheduled."
                } catch {
                    message = "Subscription saved, but notification scheduling failed."
                }
            }
        } catch {
            CaptureMediaStore.remove(named: filename)
            throw error
        }
    }

    private func updateReturn(_ item: ReturnItem, name: String, merchant: String, date: Date) {
        item.itemName = name
        item.merchant = merchant
        item.deadline = date
        do {
            try modelContext.save()
            Task {
                _ = try? await returnAlerts.schedule(item)
                _ = try? await returnAlerts.scheduleWarranty(item)
            }
            message = "Receipt updated."
        } catch {
            modelContext.rollback()
            message = "Couldn't update this receipt."
        }
    }

    private func updateSubscription(_ item: SubscriptionItem, name: String, merchant: String, date: Date) {
        item.name = name
        item.merchant = merchant
        item.nextCharge = date
        do {
            try modelContext.save()
            Task { _ = try? await renewalAlerts.schedule(item) }
            message = "Subscription updated."
        } catch {
            modelContext.rollback()
            message = "Couldn't update this subscription."
        }
    }

    private func toggleReturn(_ item: ReturnItem) {
        item.isReturned.toggle()
        do {
            try modelContext.save()
            Task {
                _ = try? await returnAlerts.schedule(item)
                _ = try? await returnAlerts.scheduleWarranty(item)
            }
        } catch {
            modelContext.rollback()
            message = "Couldn't update this receipt."
        }
    }

    private func toggleSubscription(_ item: SubscriptionItem) {
        item.isActive.toggle()
        do {
            try modelContext.save()
            Task { _ = try? await renewalAlerts.schedule(item) }
        } catch {
            modelContext.rollback()
            message = "Couldn't update this subscription."
        }
    }

    private func deleteReturn(_ item: ReturnItem) {
        let id = item.id
        let image = item.attachmentName
        modelContext.delete(item)
        do {
            try modelContext.save()
            returnAlerts.cancel(id)
            returnAlerts.cancelWarranty(id)
            CaptureMediaStore.remove(named: image)
        } catch {
            modelContext.rollback()
            message = "Couldn't delete this receipt."
        }
    }

    private func deleteSubscription(_ item: SubscriptionItem) {
        let id = item.id
        let image = item.attachmentName
        modelContext.delete(item)
        do {
            try modelContext.save()
            renewalAlerts.cancel(id)
            CaptureMediaStore.remove(named: image)
        } catch {
            modelContext.rollback()
            message = "Couldn't delete this subscription."
        }
    }
}

private struct FinancialDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let name: String
    let subtitle: String
    let amountLabel: String?
    let date: Date
    let dateLabel: String
    let forecastDates: [Date]
    let warrantyDate: Date?
    let showPrimaryDate: Bool
    let purchaseDate: Date?
    let receiptNumber: String?
    let source: String?
    let imageName: String?
    let inactive: Bool
    let inactiveLabel: String
    let onToggle: () -> Void
    let onUpdate: (String, String, Date) -> Void
    let onDelete: () -> Void
    @State private var showDelete = false
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    if let image = CaptureMediaStore.image(named: imageName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    Text(name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    if !subtitle.isEmpty {
                        Text(subtitle).foregroundStyle(RemorrowStyle.secondaryText)
                    }
                    if let amountLabel {
                        Text(amountLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RemorrowStyle.violet)
                    }
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionEyebrow(title: dateLabel)
                            if showPrimaryDate {
                                Text(date.formatted(date: .complete, time: .shortened))
                                    .font(.headline)
                            } else {
                                Text("No return deadline verified yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                            if let purchaseDate {
                                Divider()
                                SectionEyebrow(title: "PURCHASED")
                                Text(purchaseDate.formatted(date: .complete, time: .omitted))
                                    .font(.subheadline.weight(.medium))
                            }
                            if let receiptNumber, !receiptNumber.isEmpty {
                                Divider()
                                SectionEyebrow(title: "RECEIPT / ORDER NUMBER")
                                Text(receiptNumber)
                                    .font(.subheadline.weight(.medium))
                                    .textSelection(.enabled)
                            }
                            if let warrantyDate {
                                Divider()
                                SectionEyebrow(title: "WARRANTY COVERAGE ENDS")
                                Text(warrantyDate.formatted(date: .complete, time: .omitted))
                                    .font(.headline)
                            }
                        }
                    }
                    if forecastDates.count > 1 {
                        RemorrowCard {
                            VStack(alignment: .leading, spacing: 11) {
                                SectionEyebrow(title: "EXPECTED FUTURE CHARGES")
                                ForEach(Array(forecastDates.enumerated()), id: \.offset) { index, date in
                                    HStack {
                                        Text(index == 0 ? "Verified next charge" : "Projected · " + String(index))
                                            .font(.caption.weight(index == 0 ? .semibold : .regular))
                                        Spacer()
                                        Text(date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                    }
                                }
                                Text("Forecast only. Verify new charge dates with the provider.")
                                    .font(.caption2)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                        }
                    }
                    if let source, !source.isEmpty {
                        RemorrowCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionEyebrow(title: "ORIGINAL SCAN")
                                Text(source).font(.subheadline)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    Button(inactive ? "Mark active" : "Mark " + inactiveLabel.lowercased()) {
                        onToggle()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Delete", role: .destructive) { showDelete = true }
                        .foregroundStyle(.red)
                        .padding(.vertical, 12)
                }
                .padding(22)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") { showEdit = true }
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showEdit) {
                FinancialEditSheet(name: name, merchant: subtitle, date: date) { name, merchant, date in
                    onUpdate(name, merchant, date)
                    dismiss()
                }
            }
            .confirmationDialog("Delete this item?", isPresented: $showDelete) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

private struct FinancialEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String, Date) -> Void
    @State private var name: String
    @State private var merchant: String
    @State private var date: Date
    @State private var verified = false

    init(name: String, merchant: String, date: Date, onSave: @escaping (String, String, Date) -> Void) {
        self.onSave = onSave
        _name = State(initialValue: name)
        _merchant = State(initialValue: merchant)
        _date = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Merchant", text: $merchant)
                }
                Section("Date") {
                    DatePicker("Confirmed date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Toggle("I've verified this date", isOn: $verified)
                    Text("Changing the date refreshes the reminder when notifications are permitted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Save changes") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines),
                               merchant.trimmingCharacters(in: .whitespacesAndNewlines), date)
                        dismiss()
                    }
                    .disabled(!verified || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Edit details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}
