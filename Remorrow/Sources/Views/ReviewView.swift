import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let proposal: ActionProposal
    let progressLabel: String
    let onSkip: () -> Void
    let matchedPlan: SavedAction?
    let onUpdate: (@MainActor (String, Date, ProposedActionKind) async throws -> Void)?
    let onConfirm: @MainActor (String, Date, ProposedActionKind) async throws -> Void

    @State private var title: String
    @State private var dueDate: Date
    @State private var kind: ProposedActionKind
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        proposal: ActionProposal,
        progressLabel: String = "",
        matchedPlan: SavedAction? = nil,
        onUpdate: (@MainActor (String, Date, ProposedActionKind) async throws -> Void)? = nil,
        onConfirm: @escaping @MainActor (String, Date, ProposedActionKind) async throws -> Void,
        onSkip: @escaping () -> Void = {}
    ) {
        self.proposal = proposal
        self.progressLabel = progressLabel
        self.matchedPlan = matchedPlan
        self.onUpdate = onUpdate
        self.onSkip = onSkip
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
                        SectionEyebrow(title: progressLabel.isEmpty ? "ALMOST THERE" : progressLabel)
                        Text("Review the details")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .tracking(-1)
                        Text("Edit the title and date before saving to your iPhone.")
                            .font(.subheadline)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                        if proposal.origin == .appleFoundationModels {
                            Label("Interpreted with Apple on-device intelligence", systemImage: "apple.intelligence")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(RemorrowStyle.violet)
                        } else {
                            Label("Private on-device interpretation", systemImage: "lock.shield")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        }
                    }

                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Label("SUGGESTED PLAN", systemImage: "checkmark.circle")
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
                            VStack(alignment: .leading, spacing: 5) {
                                if proposal.uncertaintyFlags.contains("confirmCommitment") {
                                    Text("This sounded tentative. Check whether the plan is actually confirmed.")
                                }
                                if proposal.uncertaintyFlags.contains("timeNotSpecified") {
                                    Text("No time was found. The displayed time is only a starting point—choose the correct one.")
                                } else if proposal.uncertaintyFlags.contains("confirmTime") {
                                    Text("The time was unclear. Check AM/PM and the actual due time.")
                                }
                                if proposal.uncertaintyFlags.contains("confirmRelativeDate") {
                                    Text("Relative dates such as 'next Friday' may be ambiguous. Verify the day.")
                                }
                                Text("Review the date, title and action type before saving.")
                            }
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

                    if let matchedPlan, let onUpdate {
                        RemorrowCard {
                            VStack(alignment: .leading, spacing: 9) {
                                Label("POSSIBLE RESCHEDULE", systemImage: "calendar.badge.clock")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(RemorrowStyle.violet)
                                Text(matchedPlan.title).font(.headline)
                                Text("Previously: " + matchedPlan.dueAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                Text("Does this message update that plan? Choose update or keep both.")
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                Button {
                                    guard !isSaving else { return }
                                    isSaving = true
                                    Task {
                                        defer { isSaving = false }
                                        do {
                                            try await onUpdate(title.trimmingCharacters(in: .whitespacesAndNewlines), dueDate, kind)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                        }
                                    }
                                } label: {
                                    Label("Update existing plan", systemImage: "arrow.triangle.2.circlepath")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(RemorrowStyle.violet)
                                .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                          kind.rawValue != matchedPlan.kind)
                            }
                        }
                    }

                    RemorrowPrimaryButton(title: matchedPlan == nil ? "Confirm & save" : "Save as new plan",
                                          systemImage: "checkmark", isBusy: isSaving) {
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

                    Button("Skip this suggestion") { onSkip() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RemorrowStyle.secondaryText)
                        .frame(maxWidth: .infinity)
                        .disabled(isSaving)

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
