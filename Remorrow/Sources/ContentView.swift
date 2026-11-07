import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedAction.createdAt, order: .reverse) private var saved: [SavedAction]
    @AppStorage("currentDraft") private var draft = ""
    @State private var candidate: ActionProposal?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var saveMessage: String?
    @State private var reviewPresented = false

    private let engine = LocalRulesEngine()
    private let scheduler = EventScheduler()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draft)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Text to remember")
                    HStack {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Read screenshot", systemImage: "photo.on.rectangle")
                        }
                        Spacer()
                        Button {
                            Task { await analyze() }
                        } label: {
                            if isAnalyzing { ProgressView() }
                            else { Text("Analyze") }
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
                    }
                } header: {
                    Text("Capture")
                } footer: {
                    Text("Paste a message or choose a screenshot. You always approve dates before anything is saved.")
                }
                Section("Recently saved") {
                    if saved.isEmpty {
                        Text("Your saved events and reminders will appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(saved) { item in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title).font(.headline)
                                Text(item.dueAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                Text(item.kind == "calendarEvent" ? "Calendar event" : "Reminder")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Remorrow")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $reviewPresented) {
                if let candidate {
                    ReviewView(proposal: candidate) { title, date, kind in
                        try await save(title: title, date: date, kind: kind)
                    }
                }
            }
            .alert("Remorrow", isPresented: Binding(
                get: { errorMessage != nil || saveMessage != nil },
                set: { if !$0 { errorMessage = nil; saveMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil; saveMessage = nil }
            } message: {
                Text(errorMessage ?? saveMessage ?? "")
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                Task { await readPhoto(newValue) }
            }
        }
    }

    private func analyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let input = ExtractionInput(
                text: draft,
                capturedAt: Date(),
                localeIdentifier: Locale.current.identifier,
                timeZoneIdentifier: TimeZone.current.identifier
            )
            let proposals = try await engine.extract(from: input)
            if let first = proposals.first {
                candidate = first
            } else {
                // When extraction fails, the user can provide the date manually.
                candidate = ActionProposal(
                    kind: .reminder,
                    title: String(draft.prefix(100)),
                    sourceEvidence: draft,
                    uncertaintyFlags: ["No date found; set one manually"],
                    origin: .localRules
                )
            }
            reviewPresented = true
        } catch {
            errorMessage = "Couldn't analyze this text. You can still edit it and try again."
        }
    }

    private func readPhoto(_ photo: PhotosPickerItem) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                throw OCRFailure.invalidImage
            }
            draft = try await ImageTextReader().recognize(data: data)
            if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "No readable text found. Try another image or type the text."
            }
        } catch {
            errorMessage = "Couldn't read this screenshot. Please paste or enter the text instead."
        }
        selectedPhoto = nil
    }

    @MainActor
    private func save(title: String, date: Date, kind: ProposedActionKind) async throws {
        let externalID = try await scheduler.save(title: title, date: date, kind: kind)
        modelContext.insert(SavedAction(title: title, dueAt: date, kind: kind.rawValue, externalID: externalID))
        do { try modelContext.save() }
        catch {
            // The system item may already be saved. Tell the user, don't silently retry.
            errorMessage = "Saved to Apple \(kind == .calendarEvent ? "Calendar" : "Reminders"), but couldn't add it to Remorrow's history. Don't retry without checking first."
            reviewPresented = false
            return
        }
        reviewPresented = false
        draft = ""
        saveMessage = "Saved to \(kind == .calendarEvent ? "Calendar" : "Reminders")."
    }
}
