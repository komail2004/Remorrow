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
            Form {
                Section("We found this") {
                    TextField("Title", text: $title)
                    Picker("Save as", selection: $kind) {
                        Text("Reminder").tag(ProposedActionKind.reminder)
                        Text("Calendar event").tag(ProposedActionKind.calendarEvent)
                    }
                    DatePicker("Date and time", selection: $dueDate)
                    if proposal.proposedDate == nil || !proposal.uncertaintyFlags.isEmpty {
                        Label("Check the date carefully before saving.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                    Text("Time zone: \(TimeZone.current.identifier)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Section("Original evidence") {
                    Text(proposal.sourceEvidence)
                        .textSelection(.enabled)
                }
                Section {
                    Button {
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
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView() }
                            else { Text("Confirm and save") }
                            Spacer()
                        }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: {
                    Text("Nothing is added to Calendar or Reminders unless you tap Confirm and save.")
                }
            }
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
