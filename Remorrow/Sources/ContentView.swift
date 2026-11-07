import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SavedAction.dueAt) private var saved: [SavedAction]
    @Query(sort: \ReturnItem.deadline) private var returns: [ReturnItem]
    @AppStorage("currentDraft") private var draft = ""

    @State private var candidate: ActionProposal?
    @State private var remainingCandidates: [ActionProposal] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var pendingImageData: Data?
    @State private var editorRevision = 0
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
        .fullScreenCover(isPresented: $showCamera) {
            LiveCameraView(onPhoto: { image in
                showCamera = false
                Task { await processPhoto(image) }
            }, onCancel: { showCamera = false })
            .ignoresSafeArea()
        }
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
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(RemorrowStyle.violet)
                .frame(width: 34, height: 38)
                .accessibilityHidden(true)
            Text("remorrow")
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .tracking(-1)
            Spacer()
            Label("On device", systemImage: "lock")
                .font(.caption2.weight(.medium))
                .foregroundStyle(RemorrowStyle.secondaryText)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                    Text("Today")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                }
                Spacer()
                Text(String(upcoming.count + upcomingReturns.count) + " ahead")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RemorrowStyle.violet)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(RemorrowStyle.violet.opacity(0.08), in: Capsule())
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionEyebrow(title: "UP NEXT")
                    Spacer()
                    Button("All plans") { selection = 1 }
                        .font(.caption.weight(.semibold))
                }
                if upcoming.isEmpty && upcomingReturns.isEmpty {
                    Text("Nothing pressing.")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    Text("Capture a message or photo below. Your next important date will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                } else {
                    ForEach(Array(upcoming.prefix(3))) { item in
                        NavigationLink {
                            SavedActionDetailsView(action: item) {
                                await deleteSaved(item)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.kind == "calendarEvent" ? "calendar" : "checkmark.circle")
                                    .foregroundStyle(RemorrowStyle.violet)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RemorrowStyle.primaryText)
                                        .lineLimit(2)
                                    Text(item.dueAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(RemorrowStyle.secondaryText)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(Array(upcomingReturns.prefix(2))) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox")
                                .foregroundStyle(RemorrowStyle.violet)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Return " + item.itemName).font(.subheadline.weight(.semibold))
                                Text(item.deadline.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(19)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var upcomingReturns: [ReturnItem] {
        returns.filter { !$0.isReturned && $0.deadline >= Date() }
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
                    .id(editorRevision)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .opacity(draft.isEmpty ? 0.83 : 1)
                    .accessibilityLabel("Type or paste something to remember")
            }
            .frame(height: 118)

            HStack(spacing: 8) {
                Button {
                    pasteCopiedText()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isAnalyzing)

                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        errorMessage = "Camera isn't available in this simulator. Use your iPhone or Photos."
                    }
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isAnalyzing)

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Photos", systemImage: "photo")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isAnalyzing)
            }
            .font(.caption.weight(.medium))
            .tint(RemorrowStyle.violet)

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
                    NavigationLink {
                        SavedActionDetailsView(action: item) {
                            await deleteSaved(item)
                        }
                    } label: {
                        SavedActionCard(action: item)
                    }
                    .buttonStyle(.plain)
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
                            NavigationLink {
                                SavedActionDetailsView(action: item) {
                                    await deleteSaved(item)
                                }
                            } label: {
                                SavedActionCard(action: item)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                    Button("Delete saved action", systemImage: "trash", role: .destructive) {
                                        Task { _ = await deleteSaved(item) }
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
    private func deleteSaved(_ action: SavedAction) async -> Bool {
        do {
            try await scheduler.delete(kind: action.kind, externalID: action.externalID)
            modelContext.delete(action)
            try modelContext.save()
            CaptureMediaStore.remove(named: action.attachmentName)
            saveMessage = "Removed the saved action."
            return true
        } catch {
            errorMessage = "Couldn't completely remove this plan. " + error.localizedDescription
            return false
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
                pendingImageData = image
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
                    title: SmartTitleGenerator.title(from: draft),
                    sourceEvidence: draft,
                    uncertaintyFlags: ["No date found; set one manually"],
                    origin: .localRules)
            }
            reviewPresented = true
        } catch {
            errorMessage = "Couldn't analyze that yet. You can edit the text or try again."
        }
    }

    @MainActor
    private func processPhoto(_ data: Data) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            pendingImageData = data
            draft = try await ImageTextReader().recognize(data: data)
            if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "No readable text. Retake the photo or type the details."
            } else {
                await analyze()
            }
        } catch {
            errorMessage = "Couldn't read this photo. Try again with clearer text."
        }
    }

    private func readPhoto(_ photo: PhotosPickerItem) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                throw OCRFailure.invalidImage
            }
            pendingImageData = data
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
        let item = SavedAction(title: title, dueAt: date, kind: kind.rawValue, externalID: externalID)
        item.sourceText = draft
        if let pendingImageData { item.attachmentName = try? CaptureMediaStore.save(pendingImageData) }
        modelContext.insert(item)
        do { try modelContext.save() }
        catch {
            errorMessage = "Saved to Apple \(kind == .calendarEvent ? "Calendar" : "Reminders"), but the local history update failed. Check the Apple app before retrying."
            reviewPresented = false
            draft = ""
            pendingImageData = nil
            selectedPhoto = nil
            editorRevision += 1
            return
        }
        if !remainingCandidates.isEmpty {
            candidate = remainingCandidates.removeFirst()
        } else {
            reviewPresented = false
            draft = ""
            pendingImageData = nil
            selectedPhoto = nil
            editorRevision += 1
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
        .modelContainer(for: [SavedAction.self, ReturnItem.self], inMemory: true)
}
