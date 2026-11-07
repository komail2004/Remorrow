import SwiftUI

struct SavedActionDetailsView: View {
    let action: SavedAction
    let onDelete: @MainActor () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var askDelete = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(action.kind == "calendarEvent" ? "CALENDAR EVENT" : "REMINDER",
                          systemImage: action.kind == "calendarEvent" ? "calendar" : "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RemorrowStyle.violet)
                    Text(action.title)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                RemorrowCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("When", systemImage: "calendar")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RemorrowStyle.secondaryText)
                        Text(action.dueAt.formatted(date: .complete, time: .shortened))
                            .font(.headline)
                        Text("Time zone: \(TimeZone.current.identifier)")
                            .font(.caption).foregroundStyle(RemorrowStyle.secondaryText)
                        Divider()
                        Label("Saved to", systemImage: "checkmark.circle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RemorrowStyle.secondaryText)
                        Text(action.kind == "calendarEvent" ? "Apple Calendar" : "Apple Reminders")
                            .font(.subheadline.weight(.semibold))
                        Divider()
                        Text("Added " + action.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }
                }
                if let source = action.sourceText, !source.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionEyebrow(title: "ORIGINAL NOTE")
                        Text(source)
                            .font(.body)
                            .textSelection(.enabled)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }
                }
                if let image = CaptureMediaStore.image(named: action.attachmentName) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionEyebrow(title: "ATTACHED PHOTO")
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .accessibilityLabel("Captured source image")
                    }
                }
                Button(role: .destructive) { askDelete = true } label: {
                    Label("Delete this plan", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(14)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isDeleting)
            }
            .padding(22)
        }
        .background(RemorrowStyle.canvas.ignoresSafeArea())
        .navigationTitle("Plan details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete from Remorrow and Apple Calendar or Reminders?",
                            isPresented: $askDelete, titleVisibility: .visible) {
            Button("Delete plan", role: .destructive) {
                isDeleting = true
                Task {
                    await onDelete()
                    isDeleting = false
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deleting also removes the matching Apple event or reminder when it can be found.")
        }
    }
}
