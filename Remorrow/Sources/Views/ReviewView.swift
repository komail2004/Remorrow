import SwiftUI

struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let proposal: ActionProposal
    let progressLabel: String
    let onSkip: () -> Void
    let matchedPlan: SavedAction?
    let existingPlans: [SavedPlanRecord]
    let onUpdate: (@MainActor (UUID, String, Date, ProposedActionKind) async throws -> Void)?
    let onConfirm: @MainActor (String, Date, ProposedActionKind, Bool, Bool) async throws -> Void
    let onMoveSavedEvent: (@MainActor (UUID, Date, Date) async throws -> Void)?

    @State private var title: String
    @State private var dueDate: Date
    @State private var kind: ProposedActionKind
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showConflictConfirmation = false
    @State private var resolvingConflict: PlanConflict?
    @State private var checkedCalendarSlot: Date?
    @State private var hasVerifiedMissingDate = false

    init(
        proposal: ActionProposal,
        progressLabel: String = "",
        matchedPlan: SavedAction? = nil,
        existingPlans: [SavedPlanRecord] = [],
        onUpdate: (@MainActor (UUID, String, Date, ProposedActionKind) async throws -> Void)? = nil,
        onConfirm: @escaping @MainActor (String, Date, ProposedActionKind, Bool, Bool) async throws -> Void,
        onMoveSavedEvent: (@MainActor (UUID, Date, Date) async throws -> Void)? = nil,
        onSkip: @escaping () -> Void = {}
    ) {
        self.proposal = proposal
        self.progressLabel = progressLabel
        self.matchedPlan = matchedPlan
        self.existingPlans = existingPlans
        self.onUpdate = onUpdate
        self.onSkip = onSkip
        self.onConfirm = onConfirm
        self.onMoveSavedEvent = onMoveSavedEvent
        _title = State(initialValue: proposal.title)
        _dueDate = State(initialValue: proposal.proposedDate ??
            ExplicitTimeParser.suggestedPickerDate(
                hour: proposal.suggestedHour, minute: proposal.suggestedMinute))
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

                    if kind == .calendarEvent,
                       let overlap = conflicts.first(where: {
                           $0.reason == .overlappingEvent
                       }), onMoveSavedEvent != nil {
                        Button {
                            resolvingConflict = overlap
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: "sparkles")
                                    .font(.title3)
                                    .frame(width: 35)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("You have a schedule conflict")
                                        .font(.subheadline.weight(.bold))
                                    Text("Find a solution in one question")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.86))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(
                                LinearGradient(colors: [RemorrowStyle.violet,
                                                        RemorrowStyle.deepBlue],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 17)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("resolveConflictButton")
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
                                if proposal.proposedDate == nil {
                                    VStack(alignment: .leading, spacing: 9) {
                                        if proposal.suggestedHour != nil {
                                            HStack(spacing: 6) {
                                                Image(systemName: "clock.badge.checkmark")
                                                Text("Time recognized: " +
                                                     dueDate.formatted(date: .omitted,
                                                                       time: .shortened))
                                            }
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(RemorrowStyle.violet)
                                        }
                                        Text("The message didn't specify a calendar date. Choose the actual day before saving.")
                                            .font(.caption)
                                            .foregroundStyle(RemorrowStyle.secondaryText)
                                        Toggle("I verified the date", isOn: $hasVerifiedMissingDate)
                                            .font(.subheadline.weight(.semibold))
                                            .tint(RemorrowStyle.violet)
                                            .accessibilityIdentifier("confirmMissingDate")
                                    }
                                    .padding(12)
                                    .background(RemorrowStyle.blueTint.opacity(0.48),
                                                in: RoundedRectangle(cornerRadius: 13))
                                }
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
                                if proposal.proposedDate == nil {
                                    Text(proposal.suggestedHour != nil
                                         ? "7 PM or another stated time was recognized, but no date was provided. Confirm the actual day."
                                         : "No verified date or time was found. Choose and confirm the actual date and time.")
                                }
                                if proposal.uncertaintyFlags.contains("confirmResponsibility") {
                                    Text("Check that this is your responsibility, not somebody else's.")
                                }
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

                    if let target = updateTarget, let onUpdate {
                        RemorrowCard {
                            VStack(alignment: .leading, spacing: 11) {
                                Label(samePlanConflict?.reason == .likelyDuplicate
                                      ? "ALREADY SAVED THIS PLAN"
                                      : "POSSIBLY THE SAME PLAN",
                                      systemImage: "square.on.square")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(RemorrowStyle.violet)
                                Text(target.title)
                                    .font(.headline)
                                Text("Already scheduled: " +
                                     target.dueAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                Text(samePlanConflict?.reason == .samePlanDifferentTime
                                     ? "This looks like the same activity with a different time. Is it a reschedule?"
                                     : "This might already be on your calendar. You can update it, skip it, or deliberately keep both.")
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                Button {
                                    guard !isSaving else { return }
                                    isSaving = true
                                    Task {
                                        defer { isSaving = false }
                                        do {
                                            try await onUpdate(
                                                target.id,
                                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                dueDate,
                                                kind
                                            )
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
                                .disabled(isSaving ||
                                          (proposal.proposedDate == nil && !hasVerifiedMissingDate) ||
                                          title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                          kind.rawValue != target.kind)
                            }
                        }
                    }

                    if !conflicts.isEmpty {
                        RemorrowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("CHECK BEFORE ADDING ANOTHER",
                                      systemImage: "calendar.badge.exclamationmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.orange)
                                if let duplicate = samePlanConflict {
                                    Text(duplicate.reason == .likelyDuplicate
                                         ? "A likely duplicate is already saved."
                                         : "A very similar plan is saved for another time.")
                                        .font(.subheadline.weight(.semibold))
                                }
                                let overlaps = conflicts.filter { $0.reason == .overlappingEvent }
                                ForEach(overlaps.prefix(2)) { item in
                                    HStack(alignment: .top, spacing: 9) {
                                        Image(systemName: "clock")
                                            .foregroundStyle(.orange)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.record.title).font(.subheadline.weight(.semibold))
                                            Text("Overlaps · " + item.record.dueAt.formatted(
                                                date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(RemorrowStyle.secondaryText)
                                        }
                                    }
                                }
                                Text("No calendar changes happen without your confirmation. Separate plans can still overlap.")
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                        }
                    }

                    RemorrowPrimaryButton(
                        title: conflicts.isEmpty
                            ? (updateTarget == nil ? "Confirm & save" : "Save as another plan")
                            : "Review before saving another",
                        systemImage: conflicts.isEmpty ? "checkmark" : "exclamationmark.circle",
                        isBusy: isSaving
                    ) {
                        guard !isSaving else { return }
                        if conflicts.isEmpty {
                            saveNew(allowConflict: false)
                        } else {
                            showConflictConfirmation = true
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (proposal.proposedDate == nil && !hasVerifiedMissingDate))

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
            .confirmationDialog(
                samePlanConflict == nil ? "Save overlapping plan?" : "Keep a separate copy?",
                isPresented: $showConflictConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save separate plan anyway") {
                    saveNew(allowConflict: true)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(samePlanConflict == nil
                     ? "Another event is already scheduled at this time. Save both only if they are genuinely separate plans."
                     : "This looks like a plan you have already saved. Updating the original or skipping this suggestion may be better.")
            }
            .sheet(item: $resolvingConflict) { conflict in
                ResolveConflictView(
                    proposedTitle: title,
                    proposedStart: dueDate,
                    proposedSavedPlan: nil,
                    conflictingPlan: conflict.record,
                    onChooseProposedTime: { newTime in
                        dueDate = newTime
                        checkedCalendarSlot = newTime
                    },
                    onMoveSavedEvent: { id, newTime in
                        guard let onMoveSavedEvent else {
                            throw ScheduleFailure.itemNotFound
                        }
                        try await onMoveSavedEvent(id, newTime, dueDate)
                    }
                )
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
    private var conflicts: [PlanConflict] {
        // Do not report conflicts against an illustrative placeholder day.
        guard proposal.proposedDate != nil || hasVerifiedMissingDate else { return [] }
        return PlanConflictDetector.find(
            title: title,
            dueAt: dueDate,
            kind: kind.rawValue,
            among: existingPlans
        )
    }

    private var samePlanConflict: PlanConflict? {
        conflicts.first(where: { $0.isSamePlan })
    }

    private var updateTarget: SavedPlanRecord? {
        if let duplicate = samePlanConflict { return duplicate.record }
        // A true reschedule may change the day, so preserve the original
        // reschedule detector as a secondary, conservative suggestion.
        if let matchedPlan,
           kind.rawValue == matchedPlan.kind,
           PlanMatcher.similar(title, matchedPlan.title) {
            return SavedPlanRecord(id: matchedPlan.id, title: matchedPlan.title,
                                   dueAt: matchedPlan.dueAt, kind: matchedPlan.kind)
        }
        return nil
    }

    private func saveNew(allowConflict: Bool) {
        guard !isSaving &&
              (proposal.proposedDate != nil || hasVerifiedMissingDate) else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await onConfirm(
                    title.trimmingCharacters(in: .whitespacesAndNewlines),
                    dueDate,
                    kind,
                    allowConflict,
                    kind == .calendarEvent && checkedCalendarSlot == dueDate
                )
            } catch {
                errorMessage = error.localizedDescription
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
        onConfirm: { _, _, _, _, _ in }
    )
}
