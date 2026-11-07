import SwiftUI
import SwiftData

struct ReturnsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReturnItem.deadline) private var returns: [ReturnItem]
    @State private var showingAdd = false
    @State private var errorMessage: String?
    @State private var noticeMessage: String?
    private let notifications = ReturnNotificationScheduler()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionEyebrow(title: "A LITTLE EXTRA PEACE OF MIND")
                    Text("Returns")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(-1)
                    Text("Your return windows, without the mental clutter.")
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)

                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "shippingbox.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(RemorrowStyle.violet)
                            Text("Make sure it's not too late.")
                                .font(.system(size: 21, weight: .bold, design: .rounded))
                            Text("Add an item and confirm the retailer's actual last return date. Remorrow can remind you before it passes.")
                                .font(.subheadline)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            RemorrowPrimaryButton(title: "Add a return", systemImage: "plus", isBusy: false) {
                                showingAdd = true
                            }
                        }
                    }
                    SectionEyebrow(title: "YOUR RETURN WINDOWS")
                    if returns.isEmpty {
                        Text("Nothing here yet. Add your first item above.")
                            .font(.subheadline)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                            .padding(.top, 10)
                    } else {
                        ForEach(returns) { item in
                            RemorrowCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(item.itemName)
                                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            Text(item.merchant.isEmpty ? "Store not specified" : item.merchant)
                                                .font(.subheadline)
                                                .foregroundStyle(RemorrowStyle.secondaryText)
                                        }
                                        Spacer()
                                        Image(systemName: item.isReturned ? "checkmark.seal.fill" : "shippingbox")
                                            .foregroundStyle(RemorrowStyle.violet)
                                    }
                                    Label(item.isReturned ? "Returned" : "Deadline: " + item.deadline.formatted(date: .abbreviated, time: .shortened),
                                          systemImage: item.isReturned ? "checkmark.circle" : "calendar")
                                        .font(.subheadline)
                                    HStack {
                                        if !item.isReturned {
                                            Button("Mark returned") { changeStatus(item, returned: true) }
                                        } else {
                                            Button("Mark active") { changeStatus(item, returned: false) }
                                        }
                                        Spacer()
                                        Button("Delete", role: .destructive) { delete(item) }
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .tint(RemorrowStyle.violet)
                                }
                            }
                        }
                    }
                }
                .padding(22)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAdd) {
                AddReturnView { item in
                    try modelContext.insert(item)
                    try modelContext.save()
                    do {
                        let scheduled = try await notifications.schedule(item)
                        noticeMessage = scheduled ? "Return saved. An alert is scheduled." : "Return saved. No alert was scheduled; check notification permissions and the deadline."
                    } catch {
                        noticeMessage = "Return saved, but the notification couldn't be scheduled."
                    }
                }
            }
            .alert("Remorrow", isPresented: Binding(
                get: { errorMessage != nil || noticeMessage != nil },
                set: { if !$0 { errorMessage = nil; noticeMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil; noticeMessage = nil }
            } message: {
                Text(errorMessage ?? noticeMessage ?? "")
            }
        }
    }

    private func changeStatus(_ item: ReturnItem, returned: Bool) {
        let previous = item.isReturned
        item.isReturned = returned
        do {
            try modelContext.save()
            Task {
                do {
                    let scheduled = try await notifications.schedule(item)
                    if !returned && !scheduled {
                        noticeMessage = "Return marked active, but no alert could be scheduled."
                    }
                } catch {
                    noticeMessage = "Status updated, but the notification couldn't be updated."
                }
            }
        } catch {
            item.isReturned = previous
            errorMessage = "Couldn't save the change."
        }
    }

    private func delete(_ item: ReturnItem) {
        let id = item.id
        modelContext.delete(item)
        do {
            try modelContext.save()
            notifications.cancel(id)
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn't delete this return."
        }
    }
}

private struct AddReturnView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: @MainActor (ReturnItem) async throws -> Void
    @State private var name = ""
    @State private var merchant = ""
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var confirmed = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("What are you returning?", text: $name)
                    TextField("Store (optional)", text: $merchant)
                }
                Section("Return deadline") {
                    DatePicker("Last eligible day", selection: $deadline, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    Toggle("I verified this deadline with the retailer", isOn: $confirmed)
                    Text("A receipt's purchase date does not necessarily tell you when returns expire.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button {
                        isSaving = true
                        Task {
                            defer { isSaving = false }
                            do {
                                let item = ReturnItem(itemName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      deadline: deadline)
                                try await onAdd(item)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView() } else { Text("Save return") }
                            Spacer()
                        }
                    }
                    .disabled(isSaving || !confirmed || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || deadline <= Date())
                }
            }
            .navigationTitle("New return")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }
}
