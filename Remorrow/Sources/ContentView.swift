import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SavedAction.dueAt) private var saved: [SavedAction]
    @AppStorage("currentDraft") private var draft = ""

    @State private var candidate: ActionProposal?
    @State private var remainingCandidates: [ActionProposal] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var saveMessage: String?
    @State private var reviewPresented = false
    @State private var selection = 0
    @State private var importingShare = false

    private let engine = LocalRulesEngine()
    private let scheduler = EventScheduler()

    private var upcoming: [SavedAction] {
        saved.filter { $0.dueAt >= Calendar.current.startOfDay(for: Date()) }
    }

    var body: some View {
        TabView(selection: $selection) {
            home
                .tabItem { Label("Today", systemImage: "house.fill") }
                .tag(0)
            library
                .tabItem { Label("My plans", systemImage: "calendar") }
                .tag(1)
            ReturnsView()
                .tabItem { Label("Returns", systemImage: "shippingbox") }
                .tag(2)
            settings
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .tint(RemorrowStyle.violet)
        .sheet(isPresented: $reviewPresented) {
            if let candidate {
                ReviewView(proposal: candidate) { title, date, kind in
                    try await save(title: title, date: date, kind: kind)
                }
                .id(candidate.id)
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
        .task { await importSharedContent() }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active { Task { await importSharedContent() } }
        }
    }

    private var home: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    hero
                    captureCard
                    upcomingSection
                    philosophyFooter
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 38)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(RemorrowStyle.violet)
                        .frame(width: 45, height: 45)
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-13))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("remorrow")
                        .font(.system(size: 25, weight: .heavy, design: .rounded))
                        .tracking(-1.3)
                    Text("the little things, remembered.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
            }
            Spacer()
            Circle()
                .fill(RemorrowStyle.surface)
                .frame(width: 43, height: 43)
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RemorrowStyle.violet)
                }
                .accessibilityHidden(true)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 23) {
            HStack {
                Label("YOUR SPACE TO REMEMBER", systemImage: "sparkle")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.white.opacity(0.65))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Less on your mind.\nMore in your day.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .tracking(-1.25)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Bring the things you want to remember.\nWe'll help you make a plan.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(3)
            }

            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 17))
                Text(upcoming.isEmpty ? "A fresh start, just for you" : "\(upcoming.count) upcoming \(upcoming.count == 1 ? "plan" : "plans")")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white.opacity(0.18), in: Capsule())
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.34, green: 0.24, blue: 0.76),
                             Color(red: 0.51, green: 0.42, blue: 0.92),
                             Color(red: 0.70, green: 0.55, blue: 0.91)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .strokeBorder(.white.opacity(0.12), lineWidth: 35)
                        .frame(width: 230, height: 230)
                        .offset(x: 110, y: -96)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .accessibilityElement(children: .combine)
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    SectionEyebrow(title: "QUICK CAPTURE")
                    Text("What's coming up?")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                }
                Spacer()
                Image(systemName: "text.quote")
                    .foregroundStyle(RemorrowStyle.violet)
                    .font(.system(size: 20))
                    .frame(width: 45, height: 45)
                    .background(RemorrowStyle.violet.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RemorrowStyle.canvas)
                if draft.isEmpty {
                    Text("e.g. Dinner with Ava next Friday at 7...\nOr paste a message someone sent you.")
                        .foregroundStyle(RemorrowStyle.secondaryText)
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.top, 17)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $draft)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .opacity(draft.isEmpty ? 0.83 : 1)
                    .accessibilityLabel("Type or paste something to remember")
            }
            .frame(height: 118)

            HStack(spacing: 10) {
                Button {
                    pasteCopiedText()
                } label: {
                    Label("Paste & analyze", systemImage: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RemorrowStyle.violet)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 42)
                        .background(RemorrowStyle.violet.opacity(0.09), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isAnalyzing)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Add screenshot", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RemorrowStyle.violet)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 42)
                        .background(RemorrowStyle.violet.opacity(0.09), in: Capsule())
                }
                .disabled(isAnalyzing)
            }

            Text("From Messages: long-press a message and copy it, then tap Paste & analyze. For supported apps, use Share → Remorrow.")
                .font(.system(size: 11))
                .foregroundStyle(RemorrowStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            RemorrowPrimaryButton(title: "Find what matters", systemImage: "arrow.up.right", isBusy: isAnalyzing) {
                Task { await analyze() }
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(20)
        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 27, style: .continuous))
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    SectionEyebrow(title: "STAY AHEAD")
                    Text("On your radar")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Spacer()
                Button("See all") { selection = 1 }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RemorrowStyle.violet)
            }

            if upcoming.isEmpty {
                RemorrowCard {
                    HStack(spacing: 15) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 25))
                            .foregroundStyle(RemorrowStyle.violet)
                            .frame(width: 55, height: 55)
                            .background(RemorrowStyle.violet.opacity(0.10), in: RoundedRectangle(cornerRadius: 17))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All clear, for now.")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("When you save your first plan, it'll appear right here.")
                                .font(.system(size: 13))
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        }
                    }
                }
            } else {
                ForEach(Array(upcoming.prefix(3))) { item in
                    SavedActionCard(action: item)
                }
            }
        }
    }

    private var philosophyFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(RemorrowStyle.violet)
            Text("Your words stay on your device.")
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
        .font(.system(size: 12, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var library: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionEyebrow(title: "YOUR THINGS")
                    Text("My plans")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .tracking(-1)
                    if saved.isEmpty {
                        RemorrowCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 26))
                                    .foregroundStyle(RemorrowStyle.violet)
                                Text("A little room for everything.")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Text("Your confirmed reminders and events will live here. Head to Today to add your first.")
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                                    .font(.subheadline)
                                Button("Start capturing") { selection = 0 }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RemorrowStyle.violet)
                                    .padding(.top, 6)
                            }
                        }
                    } else {
                        ForEach(saved) { item in
                            SavedActionCard(action: item)
                                .contextMenu {
                                    Button("Delete saved action", systemImage: "trash", role: .destructive) {
                                        Task { await deleteSaved(item) }
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var settings: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionEyebrow(title: "MAKE IT YOURS")
                    Text("Settings")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Local-first, always", systemImage: "hand.raised.shield")
                                .font(.headline)
                                .foregroundStyle(RemorrowStyle.violet)
                            Text("Remorrow processes typed text and selected screenshots on your iPhone. It only adds to Calendar or Reminders when you confirm.")
                                .font(.subheadline)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            Divider()
                            Label("No account needed", systemImage: "person.crop.circle.badge.checkmark")
                                .font(.subheadline)
                            Label("Made for the little things", systemImage: "heart")
                                .font(.subheadline)
                        }
                    }
                    Text("Version 0.1 • Early preview")
                        .font(.footnote)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @MainActor
    private func deleteSaved(_ action: SavedAction) async {
        do {
            try await scheduler.delete(kind: action.kind, externalID: action.externalID)
            modelContext.delete(action)
            try modelContext.save()
            saveMessage = "Removed the saved action."
        } catch {
            errorMessage = "Couldn't remove this from Apple Calendar or Reminders. Nothing was deleted in Remorrow. " + error.localizedDescription
        }
    }

    @MainActor
    private func importSharedContent() async {
        guard !importingShare && !reviewPresented else { return }
        importingShare = true
        defer { importingShare = false }
        do {
            guard let pending = try SharedInbox.loadOldest() else { return }
            switch pending.payload.type {
            case "text":
                draft = pending.payload.text ?? ""
            case "image":
                guard let image = pending.imageData else {
                    throw SharedInboxError.invalidPayload
                }
                draft = try await ImageTextReader().recognize(data: image)
            default:
                throw SharedInboxError.invalidPayload
            }
            try SharedInbox.remove(pending)
            selection = 0
            if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "The shared content had no readable text. Try pasting it manually."
            } else {
                await analyze()
            }
        } catch {
            // Keep queued content on failure so it can be retried safely.
            errorMessage = "Couldn't import the shared item. Reopen Remorrow or try pasting it manually."
        }
    }

    @MainActor
    private func pasteCopiedText() {
        // Read the clipboard only after an explicit button tap.
        guard let copied = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !copied.isEmpty else {
            errorMessage = "Your clipboard doesn't contain text. Copy a message first, or choose a screenshot."
            return
        }
        draft = copied
        selection = 0
        Task { await analyze() }
    }

    private func analyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let input = ExtractionInput(text: draft, capturedAt: Date(),
                localeIdentifier: Locale.current.identifier, timeZoneIdentifier: TimeZone.current.identifier)
            let proposals = try await engine.extract(from: input)
            if let first = proposals.first {
                candidate = first
                remainingCandidates = Array(proposals.dropFirst())
            } else {
                remainingCandidates = []
                candidate = ActionProposal(kind: .reminder,
                    title: String(draft.prefix(100)),
                    sourceEvidence: draft,
                    uncertaintyFlags: ["No date found; set one manually"],
                    origin: .localRules)
            }
            reviewPresented = true
        } catch {
            errorMessage = "Couldn't analyze that yet. You can edit the text or try again."
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
                errorMessage = "No readable text found. Try another screenshot or type the details."
            }
        } catch {
            errorMessage = "Couldn't read that screenshot. Try a clearer one or type the details."
        }
        selectedPhoto = nil
    }

    @MainActor
    private func save(title: String, date: Date, kind: ProposedActionKind) async throws {
        let externalID = try await scheduler.save(title: title, date: date, kind: kind)
        modelContext.insert(SavedAction(title: title, dueAt: date, kind: kind.rawValue, externalID: externalID))
        do { try modelContext.save() }
        catch {
            errorMessage = "Saved to Apple \(kind == .calendarEvent ? "Calendar" : "Reminders"), but the local history update failed. Check the Apple app before retrying."
            reviewPresented = false
            return
        }
        if !remainingCandidates.isEmpty {
            candidate = remainingCandidates.removeFirst()
        } else {
            reviewPresented = false
            draft = ""
            saveMessage = "Added to \(kind == .calendarEvent ? "Calendar" : "Reminders")."
        }
    }
}

private struct SavedActionCard: View {
    let action: SavedAction

    var body: some View {
        RemorrowCard {
            HStack(spacing: 14) {
                Image(systemName: action.kind == "calendarEvent" ? "calendar" : "checklist")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(RemorrowStyle.violet)
                    .frame(width: 50, height: 50)
                    .background(RemorrowStyle.violet.opacity(0.10), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 5) {
                    Text(action.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                    Text(action.dueAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13))
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                Spacer(minLength: 2)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green.opacity(0.7))
                    .accessibilityLabel("Saved")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedAction.self, inMemory: true)
}
