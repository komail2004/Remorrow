import SwiftUI

/// A deliberately short decision path: choose the movable commitment, see up
/// to three EventKit-verified openings, then explicitly approve the action.
struct ResolveConflictView: View {
    @Environment(\.dismiss) private var dismiss

    let proposedTitle: String
    let proposedStart: Date
    /// Non-nil when launched from My Plans with TWO already-saved events.
    let proposedSavedPlan: SavedPlanRecord?
    let conflictingPlan: SavedPlanRecord
    let onChooseProposedTime: @MainActor (Date) async throws -> Void
    let onMoveSavedEvent: @MainActor (UUID, Date) async throws -> Void

    private enum MoveChoice: String {
        case proposed, saved, either, neither
    }

    private enum PriorityChoice: String {
        case proposed, saved, uncertain
    }

    @State private var choice: MoveChoice?
    @State private var priority: PriorityChoice?
    @State private var slots: [ResolveSuggestion] = []
    @State private var selectedSlot: ResolveSuggestion?
    @State private var movingDetails: ResolveEventDetails?
    @State private var proposedDetails: ResolveEventDetails?
    @State private var checking = false
    @State private var saving = false
    @State private var verifiedCalendar = false
    @State private var errorMessage: String?
    @State private var showingMoveConfirmation = false
    @State private var showingCustomTime = false
    @State private var customTime = Date().addingTimeInterval(24 * 3600)
    @State private var customTimeIsSelected = false
    @State private var checkingCustomTime = false

    private let calendarService = ResolveCalendarService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    eventComparison

                    if choice == nil || choice == .either {
                        firstQuestion
                    } else if choice == .neither {
                        priorityQuestion
                    } else {
                        alternatives
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .navigationTitle("Resolve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .disabled(saving)
                }
            }
            .confirmationDialog(
                "Change this calendar event?",
                isPresented: $showingMoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Move event on my calendar") {
                    Task {
                        if choice == .proposed {
                            if let slot = selectedSlot {
                                await confirmProposedTime(slot)
                            }
                        } else {
                            await confirmMovingExisting()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let slot = selectedSlot {
                    Text("Move “" + (choice == .proposed
                                     ? proposedTitle : conflictingPlan.title) +
                         "” to " + slot.start.formatted(date: .complete, time: .shortened) +
                         "? Remorrow won't change the other event automatically.")
                }
            }
            .alert("Couldn't resolve conflict", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(RemorrowStyle.violet)
                SectionEyebrow(title: "REMORROW RESOLVE")
            }
            Text("Let's make room.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .tracking(-0.8)
            Text("One quick question. Up to three options from calendars you allow Remorrow to check.")
                .font(.subheadline)
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
    }

    private var eventComparison: some View {
        RemorrowCard {
            VStack(alignment: .leading, spacing: 12) {
                eventRow(symbol: "calendar", name: proposedTitle,
                         when: proposedStart, label: "NEW PLAN")
                Divider()
                eventRow(symbol: "calendar.badge.clock", name: conflictingPlan.title,
                         when: conflictingPlan.dueAt, label: "ALREADY SAVED")
            }
        }
    }

    private func eventRow(symbol: String, name: String,
                          when date: Date, label: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(RemorrowStyle.violet)
                .frame(width: 38, height: 38)
                .background(RemorrowStyle.blueTint, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                SectionEyebrow(title: label)
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }

    private var firstQuestion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(choice == .either ? "Which should we explore first?" : "Which event could move?")
                .font(.system(size: 21, weight: .bold, design: .rounded))

            choiceButton(title: proposedTitle, subtitle: "Find another time for the new plan",
                         symbol: "arrow.right", selected: false) {
                choose(.proposed)
            }
            choiceButton(title: conflictingPlan.title, subtitle: "Move the saved event instead",
                         symbol: "arrow.left", selected: false) {
                choose(.saved)
            }
            if choice != .either {
                HStack(spacing: 10) {
                    Button("Either could move") {
                        choice = .either
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RemorrowStyle.violet)

                    Spacer()

                    Button("Neither / not sure") {
                        choice = .neither
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RemorrowStyle.secondaryText)
                }
                .padding(.top, 7)
            }
        }
    }

    private var priorityQuestion: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Which is harder to miss?")
                .font(.system(size: 21, weight: .bold, design: .rounded))

            choiceButton(title: proposedTitle, subtitle: "This commitment matters more right now",
                         symbol: "checkmark.circle", selected: priority == .proposed) {
                priority = .proposed
            }
            choiceButton(title: conflictingPlan.title,
                         subtitle: "This commitment has bigger consequences",
                         symbol: "checkmark.circle", selected: priority == .saved) {
                priority = .saved
            }
            choiceButton(title: "I'm not sure",
                         subtitle: "Don't guess — explore a compromise",
                         symbol: "questionmark.circle", selected: priority == .uncertain) {
                priority = .uncertain
            }

            if let priority {
                RemorrowCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("A POSSIBLE NEXT STEP", systemImage: "lightbulb")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RemorrowStyle.violet)
                        Text(priority == .proposed
                             ? "Keep “" + proposedTitle + "” and ask whether the saved event could change."
                             : priority == .saved
                             ? "Keep “" + conflictingPlan.title + "” and ask whether the new plan could change."
                             : "Neither event is clearly movable. Ask the organizers about another time or a shorter visit.")
                            .font(.subheadline)
                        Text("This is based on your answer, not an assumption about your personal priorities.")
                            .font(.caption)
                            .foregroundStyle(RemorrowStyle.secondaryText)

                        ShareLink(item: compromiseMessage(priority)) {
                            Label("Draft a friendly message", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(RemorrowStyle.violet)
                    }
                }
            }
            Button("Back to options") {
                priority = nil
                choice = nil
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(RemorrowStyle.violet)
        }
    }

    private func choiceButton(title: String, subtitle: String, symbol: String,
                              selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: selected ? "checkmark.circle.fill" : symbol)
                    .font(.title3)
                    .frame(width: 30)
                    .foregroundStyle(RemorrowStyle.violet)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }
            .foregroundStyle(RemorrowStyle.primaryText)
            .padding(14)
            .background(RemorrowStyle.surface, in:
                            RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(selected ? RemorrowStyle.violet :
                                  RemorrowStyle.primaryText.opacity(0.04), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var alternatives: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Possible openings")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                    Text(choice == .saved ? "Move the saved event" : "Move the new plan")
                        .font(.caption)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                Spacer()
                Button("Change") {
                    choice = nil
                    slots = []
                    selectedSlot = nil
                    showingCustomTime = false
                    customTimeIsSelected = false
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(RemorrowStyle.violet)
            }

            if checking {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Checking your available calendars…")
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if slots.isEmpty {
                RemorrowCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(RemorrowStyle.violet)
                        Text(verifiedCalendar
                             ? "No suitable opening found nearby"
                             : "No available times verified yet")
                            .font(.subheadline.weight(.semibold))
                        Text(verifiedCalendar
                             ? "Nothing suitable appeared in the next eight days. Try another day or propose a time to the organizer."
                             : "Calendar permission is required to check real availability; Remorrow won't invent free slots.")
                            .font(.caption)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                        Button("Check again") {
                            Task { await checkAvailability() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RemorrowStyle.violet)
                    }
                }
            } else {
                ForEach(slots) { slot in
                    Button {
                        selectedSlot = slot
                        customTimeIsSelected = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedSlot?.id == slot.id
                                  ? "checkmark.circle.fill" : "clock")
                                .foregroundStyle(RemorrowStyle.violet)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(slot.start.formatted(
                                    .dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.subheadline.weight(.semibold))
                                Text(slot.start.formatted(date: .omitted, time: .shortened)
                                     + " – " + slot.end.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                            Spacer()
                            if selectedSlot?.id == slot.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(RemorrowStyle.violet)
                            }
                        }
                        .foregroundStyle(RemorrowStyle.primaryText)
                        .padding(14)
                        .background(selectedSlot?.id == slot.id
                                    ? RemorrowStyle.blueTint : RemorrowStyle.surface,
                                    in: RoundedRectangle(cornerRadius: 17))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("resolveSlot")
                }

            }

            customTimeOption

                if let selectedSlot {
                    if choice == .proposed {
                        if proposedSavedPlan == nil {
                            Button {
                                Task { await confirmProposedTime(selectedSlot) }
                            } label: {
                                actionLabel("Use this time", symbol: "checkmark")
                            }
                            .disabled(saving)
                            Text("You'll return to Review and confirm saving the new plan.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        } else {
                            if proposedDetails?.canMoveDirectly == true {
                                Button {
                                    showingMoveConfirmation = true
                                } label: {
                                    actionLabel("Move saved event",
                                                symbol: "calendar.badge.clock")
                                }
                                .disabled(saving)
                            }
                            ShareLink(item: proposalMessage(
                                for: selectedSlot, eventTitle: proposedTitle)) {
                                Label("Propose this time instead",
                                      systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .tint(RemorrowStyle.violet)
                        }
                    } else {
                        if movingDetails?.canMoveDirectly == true {
                            Button {
                                showingMoveConfirmation = true
                            } label: {
                                actionLabel("Move saved event", symbol: "calendar.badge.clock")
                            }
                            .disabled(saving)
                        }
                        ShareLink(item: proposalMessage(for: selectedSlot,
                                                        eventTitle: conflictingPlan.title)) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Propose this time instead")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RemorrowStyle.violet)
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                }

            if (choice == .saved && movingDetails?.canMoveDirectly == false ||
                choice == .proposed && proposedSavedPlan != nil &&
                proposedDetails?.canMoveDirectly == false) && !checking && verifiedCalendar {
                Text("This event has invitees, is read-only, or is all-day. Propose a time instead of changing a shared commitment.")
                    .font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }

            Label("Free on calendars Remorrow can access. Other people's availability and travel time are not verified.",
                  systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(RemorrowStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Manual choices use exactly the same EventKit validation as suggestions.
    /// No time is marked available or moved merely because it was selected.
    private var customTimeOption: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showingCustomTime.toggle()
                if showingCustomTime {
                    customTime = max(Date().addingTimeInterval(3600),
                                     (choice == .saved ? conflictingPlan.dueAt : proposedStart)
                                         .addingTimeInterval(24 * 3600))
                }
                if customTimeIsSelected {
                    selectedSlot = nil
                    customTimeIsSelected = false
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(RemorrowStyle.violet)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Choose my own time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RemorrowStyle.primaryText)
                        Text("Pick any future date and time")
                            .font(.caption)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }
                    Spacer()
                    Image(systemName: showingCustomTime ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                .padding(14)
                .background(RemorrowStyle.surface,
                            in: RoundedRectangle(cornerRadius: 17))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("resolveChooseOwnTime")

            if showingCustomTime {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker(
                        "Date and time",
                        selection: $customTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(RemorrowStyle.violet)
                    .accessibilityIdentifier("resolveCustomDatePicker")
                    .onChange(of: customTime) { _, _ in
                        if customTimeIsSelected {
                            selectedSlot = nil
                            customTimeIsSelected = false
                        }
                    }

                    Text("We'll verify your choice against calendars you allow Remorrow to check. Other people's schedules aren't included.")
                        .font(.caption)
                        .foregroundStyle(RemorrowStyle.secondaryText)

                    if customTimeIsSelected,
                       let selectedSlot {
                        Label(
                            "This time is free on your checked calendars: " +
                            selectedSlot.start.formatted(date: .abbreviated,
                                                          time: .shortened),
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RemorrowStyle.violet)
                        .accessibilityIdentifier("resolveCustomAvailable")
                    } else {
                        Button {
                            Task { await validateCustomTime() }
                        } label: {
                            HStack(spacing: 8) {
                                if checkingCustomTime { ProgressView() }
                                else { Image(systemName: "checkmark.shield") }
                                Text(checkingCustomTime ? "Checking availability…" : "Check this time")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(RemorrowStyle.violet)
                        .disabled(checking || checkingCustomTime || saving)
                        .accessibilityIdentifier("resolveCheckCustomTime")
                    }
                }
                .padding(14)
                .background(RemorrowStyle.blueTint.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 17))
            }
        }
    }

    @MainActor
    private func validateCustomTime() async {
        guard !checkingCustomTime, !checking, !saving,
              let choice, choice == .proposed || choice == .saved else { return }
        checkingCustomTime = true
        errorMessage = nil
        selectedSlot = nil
        customTimeIsSelected = false
        defer { checkingCustomTime = false }
        do {
            let duration = choice == .saved
                ? (movingDetails?.duration ?? 3600)
                : (proposedDetails?.duration ?? 3600)
            let movingID = choice == .saved
                ? conflictingPlan.externalID : proposedSavedPlan?.externalID
            try await calendarService.validate(
                date: customTime,
                duration: duration,
                excluding: movingID,
                alsoBlocking: choice == .saved && proposedSavedPlan == nil
                    ? [ResolveBusyInterval(start: proposedStart,
                                           end: proposedStart.addingTimeInterval(3600))]
                    : []
            )
            selectedSlot = ResolveSuggestion(start: customTime, duration: duration)
            customTimeIsSelected = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Spacer()
            if saving {
                ProgressView().tint(.white)
            } else {
                Image(systemName: symbol)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .foregroundStyle(.white)
        .frame(minHeight: 52)
        .background(RemorrowStyle.primaryAction,
                    in: RoundedRectangle(cornerRadius: 16))
    }

    private func choose(_ value: MoveChoice) {
        choice = value
        slots = []
        selectedSlot = nil
        showingCustomTime = false
        customTimeIsSelected = false
        verifiedCalendar = false
        Task { await checkAvailability() }
    }

    @MainActor
    private func checkAvailability() async {
        guard let choice, choice == .proposed || choice == .saved else { return }
        checking = true
        errorMessage = nil
        selectedSlot = nil
        customTimeIsSelected = false
        slots = []
        defer { checking = false }
        do {
            if choice == .saved {
                guard let externalID = conflictingPlan.externalID else {
                    throw ResolveCalendarError.missingEvent
                }
                let details = try await calendarService.details(externalID: externalID)
                movingDetails = details
                slots = try await calendarService.suggestions(
                    around: conflictingPlan.dueAt,
                    duration: details.duration,
                    excluding: externalID,
                    alsoBlocking: proposedSavedPlan == nil
                        ? [ResolveBusyInterval(start: proposedStart,
                                               end: proposedStart.addingTimeInterval(3600))]
                        : []
                )
            } else {
                movingDetails = nil
                if let saved = proposedSavedPlan {
                    guard let externalID = saved.externalID else {
                        throw ResolveCalendarError.missingEvent
                    }
                    let details = try await calendarService.details(externalID: externalID)
                    proposedDetails = details
                    slots = try await calendarService.suggestions(
                        around: proposedStart,
                        duration: details.duration,
                        excluding: externalID
                    )
                } else {
                    proposedDetails = nil
                    slots = try await calendarService.suggestions(
                        around: proposedStart,
                        duration: 3600
                    )
                }
            }
            verifiedCalendar = true
        } catch {
            verifiedCalendar = false
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func confirmProposedTime(_ slot: ResolveSuggestion) async {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        do {
            if let saved = proposedSavedPlan {
                guard let externalID = saved.externalID else {
                    throw ResolveCalendarError.missingEvent
                }
                let latest = try await calendarService.details(externalID: externalID)
                guard latest.canMoveDirectly else {
                    throw ResolveCalendarError.readOnlyOrShared
                }
                try await calendarService.validate(
                    date: slot.start, duration: latest.duration,
                    excluding: externalID
                )
            } else {
                try await calendarService.validate(date: slot.start,
                                                    duration: slot.duration)
            }
            // Review mode changes the editable date; My Plans mode updates
            // the explicitly confirmed saved event.
            try await onChooseProposedTime(slot.start)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func confirmMovingExisting() async {
        guard !saving, let slot = selectedSlot,
              let externalID = conflictingPlan.externalID,
              movingDetails?.canMoveDirectly == true else { return }
        saving = true
        defer { saving = false }
        do {
            let latest = try await calendarService.details(externalID: externalID)
            guard latest.canMoveDirectly else { throw ResolveCalendarError.readOnlyOrShared }
            try await calendarService.validate(
                date: slot.start, duration: latest.duration,
                excluding: externalID,
                alsoBlocking: proposedSavedPlan == nil
                    ? [ResolveBusyInterval(start: proposedStart,
                                           end: proposedStart.addingTimeInterval(3600))]
                    : []
            )
            try await onMoveSavedEvent(conflictingPlan.id, slot.start)
            // The new proposed event is still in Review, not automatically saved.
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func proposalMessage(for slot: ResolveSuggestion,
                                 eventTitle: String) -> String {
        "Would " + slot.start.formatted(date: .complete, time: .shortened) +
        " work for “" + eventTitle +
        "”? It looks free on my calendar, but I wanted to check with you before changing anything."
    }

    private func compromiseMessage(_ priority: PriorityChoice) -> String {
        let lessFlexible = priority == .proposed ? proposedTitle : conflictingPlan.title
        return priority == .uncertain
            ? "I noticed two things on my calendar overlap. Would you be open to discussing another time? I'd love to make both work."
            : "I have a scheduling conflict involving “" + lessFlexible +
              "”. Could we look at another time? I want to make sure I can give both commitments my attention."
    }
}
