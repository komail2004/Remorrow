import SwiftUI
import SwiftData

/// User-controlled review of duplicates already saved before matching existed.
/// Deletion uses the app's normal EventKit-aware flow; there is no silent merge.
struct PossibleDuplicatesView: View {
    @Query(sort: \SavedAction.createdAt) private var saved: [SavedAction]
    let onDelete: @MainActor (UUID) async -> Bool

    @AppStorage("acceptedPlanDuplicateIDs") private var acceptedPlanDuplicateIDs = ""
    @State private var selectedForDeletion: UUID?
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var pairs: [PlanDuplicatePair] {
        let records = saved.map {
            SavedPlanRecord(id: $0.id, title: $0.title,
                            dueAt: $0.dueAt, kind: $0.kind)
        }
        let accepted = Set(acceptedPlanDuplicateIDs.split(separator: ",").map(String.init))
        return PlanConflictDetector.existingDuplicates(in: records)
            .filter { !accepted.contains($0.id.uuidString) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Review possible duplicates")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("Remorrow found events that might describe the same plan. Nothing is changed automatically. Keep both or remove an extra copy from Remorrow and its linked Apple app.")
                    .font(.subheadline)
                    .foregroundStyle(RemorrowStyle.secondaryText)

                if pairs.isEmpty {
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("You're all caught up", systemImage: "checkmark.seal")
                                .font(.headline)
                                .foregroundStyle(RemorrowStyle.violet)
                            Text("No unreviewed duplicates are currently flagged.")
                                .font(.subheadline)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        }
                    }
                }

                ForEach(pairs) { pair in
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Label(pair.reason == .likelyDuplicate
                                  ? "LIKELY SAME EVENT"
                                  : "SIMILAR EVENT · DIFFERENT TIME",
                                  systemImage: "square.on.square")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RemorrowStyle.violet)

                            recordRow("Original saved plan", record: pair.original)
                            Divider()
                            recordRow("Possible extra copy", record: pair.possibleExtra)

                            HStack(spacing: 10) {
                                Button("Keep both") {
                                    let accepted = Set(acceptedPlanDuplicateIDs.split(separator: ",").map(String.init))
                                    if !accepted.contains(pair.id.uuidString) {
                                        acceptedPlanDuplicateIDs += (acceptedPlanDuplicateIDs.isEmpty ? "" : ",")
                                            + pair.id.uuidString
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(RemorrowStyle.violet)

                                Menu {
                                    Button("Remove earlier-saved copy", role: .destructive) {
                                        selectedForDeletion = pair.original.id
                                    }
                                    Button("Remove later-saved copy", role: .destructive) {
                                        selectedForDeletion = pair.possibleExtra.id
                                    }
                                } label: {
                                    Label("Choose copy to remove", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .disabled(isDeleting)
                            }
                            .font(.caption.weight(.semibold))
                            Text("Choose which time is correct. You can remove either copy, or keep both.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        }
                    }
                }
            }
            .padding(22)
        }
        .background(RemorrowStyle.canvas.ignoresSafeArea())
        .navigationTitle("Duplicates")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Remove this copy from Remorrow and Apple Calendar or Reminders?",
            isPresented: Binding(get: { selectedForDeletion != nil },
                                 set: { if !$0 { selectedForDeletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove selected copy", role: .destructive) {
                guard let id = selectedForDeletion else { return }
                selectedForDeletion = nil
                isDeleting = true
                Task {
                    let removed = await onDelete(id)
                    isDeleting = false
                    if !removed {
                        errorMessage = "Could not remove the Apple item and local copy together. No automatic merge was performed."
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                selectedForDeletion = nil
            }
        } message: {
            Text("Only the copy you selected will be removed from Remorrow and its linked Apple Calendar or Reminders item. Other plans remain untouched.")
        }
        .alert("Could not remove plan", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func recordRow(_ label: String, record: SavedPlanRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(RemorrowStyle.secondaryText)
            Text(record.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RemorrowStyle.primaryText)
            Text(record.dueAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
