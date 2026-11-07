import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let proposal: ActionProposal
    let onConfirm: @MainActor (String, Date, ProposedActionKind) async throws -> Void

    @State private var title: String
    @State private var dueDate: Date
    @State private var kind: ProposedActionKind
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        proposal: ActionProposal,
        onConfirm: @escaping @MainActor (String, Date, ProposedActionKind) async throws -> Void
    ) {
        self.proposal = proposal
        self.onConfirm = onConfirm
        _title = State(initialValue: proposal.title)
        _dueDate = State(initialValue: proposal.proposedDate ?? Date().addingTimeInterval(3600))
        _kind = State(initialValue: proposal.kind == .shoppingReturn ? .reminder : proposal.kind)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionEyebrow(title: "ALMOST THERE")
                        Text("Make it yours.")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .tracking(-1)
                        Text("We picked out a possible plan. Check the details before it goes anywhere.")
                            .font(.subheadline)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }

                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Label("YOUR PLAN", systemImage: "sparkles.rectangle.stack")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(RemorrowStyle.violet)

                            VStack(alignment: .leading, spacing: 7) {
                                Text("TITLE").font(.caption2.weight(.bold))
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                TextField("What is it?", text: $title)
                                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                                    .textFieldStyle(.plain)
                                    .padding(13)
                                    .background(RemorrowStyle.canvas, in: RoundedRectangle(cornerRadius: 13))
                            }

                            VStack(alignment: .leading, spacing: 7) {
                                Text("SEND TO").font(.caption2.weight(.bold))
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                Picker("Save as", selection: $kind) {
                                    Text("Reminder").tag(ProposedActionKind.reminder)
                                    Text("Calendar event").tag(ProposedActionKind.calendarEvent)
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("WHEN").font(.caption2.weight(.bold))
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                DatePicker("Date and time", selection: $dueDate)
                                    .datePickerStyle(.graphical)
                                    .tint(RemorrowStyle.violet)
                                Text("Time zone: \(TimeZone.current.identifier)")
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                        }
                    }

                    if proposal.proposedDate == nil || !proposal.uncertaintyFlags.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Please confirm the date and action type. Extracted details may not be exact.")
                                .font(.system(size: 13))
                                .foregroundStyle(RemorrowStyle.primaryText)
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 17))
                    }

                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionEyebrow(title: "FROM YOUR MESSAGE")
                            Text(proposal.sourceEvidence)
                                .font(.system(size: 14))
                                .foregroundStyle(RemorrowStyle.secondaryText)
                                .textSelection(.enabled)
                        }
                    }

                    RemorrowPrimaryButton(title: "Confirm & save", systemImage: "checkmark", isBusy: isSaving) {
                        guard !isSaving else { return }
                        isSaving = true
                        Task {
                            defer { isSaving = false }
                            do {
                                try await onConfirm(title.trimmingCharacters(in: .whitespacesAndNewlines), dueDate, kind)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("Nothing goes to Calendar or Reminders without your approval.")
                        .font(.system(size: 12))
                        .foregroundStyle(RemorrowStyle.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(22)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

#Preview {
    ReviewView(
        proposal: ActionProposal(
            kind: .calendarEvent,
            title: "Dinner with Ava",
            sourceEvidence: "Dinner with Ava next Friday at 7.",
            proposedDate: .now,
            uncertaintyFlags: ["confirmDate"],
            origin: .localRules
        ),
        onConfirm: { _, _, _ in }
    )
}
