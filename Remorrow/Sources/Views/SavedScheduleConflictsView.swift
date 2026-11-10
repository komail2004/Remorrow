import SwiftUI
import SwiftData

/// Existing overlaps are visible only when the user opens My Plans.
/// No calendar scan or change happens automatically in this view.
struct SavedScheduleConflictsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedAction.dueAt) private var saved: [SavedAction]

    @AppStorage("acknowledgedScheduleClashes") private var acknowledged = ""
    let onMoveEvent: @MainActor (UUID, Date, Date) async throws -> Void

    @State private var selected: SavedScheduleClash?

    private var clashes: [SavedScheduleClash] {
        let stored = saved.map {
            SavedPlanRecord(id: $0.id, title: $0.title,
                            dueAt: $0.dueAt, kind: $0.kind,
                            externalID: $0.externalID)
        }
        let accepted = Set(acknowledged.split(separator: ",").map(String.init))
        return SavedScheduleClashDetector.find(stored)
            .filter { !accepted.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(RemorrowStyle.violet)
                        .frame(width: 48, height: 48)
                        .background(RemorrowStyle.blueTint, in:
                                        RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Make room for both.")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                        Text("Review overlapping saved plans at your pace.")
                            .font(.subheadline)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }
                }

                if clashes.isEmpty {
                    RemorrowCard {
                        Label("No unreviewed schedule clashes.", systemImage: "checkmark.seal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RemorrowStyle.violet)
                    }
                }

                ForEach(clashes) { clash in
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 13) {
                            SectionEyebrow(title: "POSSIBLE SCHEDULE CONFLICT")
                            conflictRow(clash.first)
                            Divider()
                            conflictRow(clash.second)
                            Button {
                                selected = clash
                            } label: {
                                Label("Find a solution", systemImage: "sparkles")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(RemorrowStyle.violet,
                                                in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            Button("Keep both") {
                                let accepted = Set(acknowledged.split(separator: ",").map(String.init))
                                if !accepted.contains(clash.id) {
                                    acknowledged += (acknowledged.isEmpty ? "" : ",") + clash.id
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RemorrowStyle.secondaryText)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                Text("Overlaps are estimates from Remorrow's saved events. When you choose Resolve, the app checks real durations and calendar availability before suggesting alternatives.")
                    .font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }
            .padding(22)
        }
        .background(RemorrowStyle.canvas.ignoresSafeArea())
        .navigationTitle("Schedule conflicts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { pair in
            ResolveConflictView(
                proposedTitle: pair.first.title,
                proposedStart: pair.first.dueAt,
                proposedSavedPlan: pair.first,
                conflictingPlan: pair.second,
                onChooseProposedTime: { date in
                    try await onMoveEvent(pair.first.id, date, pair.second.dueAt)
                },
                onMoveSavedEvent: { id, date in
                    try await onMoveEvent(id, date, pair.first.dueAt)
                }
            )
        }
    }

    private func conflictRow(_ record: SavedPlanRecord) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "calendar")
                .foregroundStyle(RemorrowStyle.violet)
                .frame(width: 31, height: 31)
                .background(RemorrowStyle.blueTint,
                            in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(.subheadline.weight(.semibold))
                Text(record.dueAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }
            Spacer()
        }
    }
}
