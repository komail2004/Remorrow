import SwiftUI
import PhotosUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SavedAction.dueAt) private var saved: [SavedAction]
    @Query(sort: \ReturnItem.deadline) private var returns: [ReturnItem]
    @Query(sort: \SubscriptionItem.nextCharge) private var subscriptions: [SubscriptionItem]
    @AppStorage("currentDraft") private var draft = ""
    @AppStorage("showDetailsInWidgets") private var showDetailsInWidgets = false
    @AppStorage("smartNotificationsEnabled") private var smartAlerts = false
    @AppStorage("dailyBriefingEnabled") private var dailyBriefingEnabled = false
    @AppStorage("dailyBriefingHour") private var dailyBriefingHour = 8
    @State private var notificationStatus: String?
    @AppStorage("completedWelcomeGuideV1") private var hasCompletedWelcome = false
    @State private var showingWelcome = false

    @State private var candidate: ActionProposal?
    @State private var remainingCandidates: [ActionProposal] = []
    @State private var totalCandidates = 1
    @State private var reviewedCount = 0
    @State private var savedCandidateCount = 0
    @State private var activeReviewSource = ""
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

    private let engine = SmartExtractionPipeline()
    private let scheduler = EventScheduler()

    private enum AgendaEntry: Identifiable {
        case plan(SavedAction)
        case shoppingReturn(ReturnItem)
        case subscription(SubscriptionItem)

        var id: String {
            switch self {
            case .plan(let item): "plan-" + item.id.uuidString
            case .shoppingReturn(let item): "return-" + item.id.uuidString
            case .subscription(let item): "subscription-" + item.id.uuidString
            }
        }

        var dueAt: Date {
            switch self {
            case .plan(let item): item.dueAt
            case .shoppingReturn(let item): item.deadline
            case .subscription(let item): item.nextCharge
            }
        }
    }

    private var upcoming: [SavedAction] {
        saved.filter { $0.dueAt >= Date().addingTimeInterval(-7 * 24 * 60 * 60) }
    }

    private var agenda: [AgendaEntry] {
        let actions = upcoming.map { AgendaEntry.plan($0) }
        let returns = upcomingReturns.map { AgendaEntry.shoppingReturn($0) }
        let charges = subscriptions.filter { $0.isActive && $0.nextCharge >= Date().addingTimeInterval(-7 * 24 * 60 * 60) }
            .map { AgendaEntry.subscription($0) }
        return (actions + returns + charges).sorted { $0.dueAt < $1.dueAt }
    }

    private var briefing: DailyBriefing {
        let plans = saved.map {
            BriefingEntry(id: "plan-" + $0.id.uuidString, title: $0.title, dueAt: $0.dueAt, kind: $0.kind)
        }
        let purchases = returns.filter { !$0.isReturned && $0.hasConfirmedReturnDeadline }.map {
            BriefingEntry(id: "receipt-" + $0.id.uuidString, title: "Return " + $0.itemName,
                          dueAt: $0.deadline, kind: "return")
        }
        let charges = subscriptions.filter { $0.isActive }.map {
            BriefingEntry(id: "charge-" + $0.id.uuidString, title: $0.name,
                          dueAt: $0.nextCharge, kind: "subscription")
        }
        return DailyBriefing.build(items: plans + purchases + charges)
    }

    private var briefingFingerprint: String {
        (briefing.overdue + briefing.today + briefing.soon)
            .map { $0.id + String(Int($0.dueAt.timeIntervalSince1970)) + $0.title }
            .joined(separator: "|")
    }

    var body: some View {
        TabView(selection: $selection) {
            home
                .tabItem { Label("Today", systemImage: "house.fill") }
                .tag(0)
            library
                .tabItem { Label("My plans", systemImage: "calendar") }
                .tag(1)
            ReceiptsSubscriptionsView()
                .tabItem { Label("Receipts", systemImage: "creditcard") }
                .tag(2)
            settings
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .tint(RemorrowStyle.violet)
        .fullScreenCover(isPresented: $showingWelcome) {
            WelcomeGuideView {
                hasCompletedWelcome = true
                showingWelcome = false
                Task { await importSharedContent() }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            LiveCameraView(onPhoto: { image in
                showCamera = false
                Task { await processPhoto(image) }
            }, onCancel: { showCamera = false })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $reviewPresented) {
            if let candidate {
                ReviewView(
                    proposal: candidate,
                    progressLabel: totalCandidates > 1
                        ? "Suggestion " + String(reviewedCount + 1) + " of " + String(totalCandidates)
                        : "",
                    matchedPlan: matchingPlan(for: candidate),
                    onUpdate: { title, date, kind in
                        guard let match = matchingPlan(for: candidate) else { throw ScheduleFailure.itemNotFound }
                        try await updateSaved(match, title: title, date: date, kind: kind)
                    },
                    onConfirm: { title, date, kind in
                        try await save(title: title, date: date, kind: kind)
                    },
                    onSkip: { skipCurrentCandidate() }
                )
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
        .task {
            WidgetSnapshotWriter.publish(briefing: briefing, allowDetails: showDetailsInWidgets)
            if ProcessInfo.processInfo.arguments.contains("--remorrow-ui-guide") {
                hasCompletedWelcome = false
            }
            if !hasCompletedWelcome {
                showingWelcome = true
            } else {
                await importSharedContent()
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active && hasCompletedWelcome {
                Task { await importSharedContent() }
            }
        }
        .onChange(of: briefingFingerprint) { _, _ in
            WidgetSnapshotWriter.publish(briefing: briefing, allowDetails: showDetailsInWidgets)
        }
        .onChange(of: showDetailsInWidgets) { _, _ in
            WidgetSnapshotWriter.publish(briefing: briefing, allowDetails: showDetailsInWidgets)
        }
        .onChange(of: reviewPresented) { _, presented in
            // A partially saved conversation must not leave the same text
            // ready to be reanalyzed and accidentally re-saved as duplicates.
            if !presented && savedCandidateCount > 0 && candidate == nil {
                draft = ""
                pendingImageData = nil
                selectedPhoto = nil
                editorRevision += 1
            }
        }
    }

    private var home: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    DailyBriefingCard(briefing: briefing)
                    hero
                    captureShortcuts
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
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 11) {
                Image("RemorrowMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                Text("remorrow")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .tracking(-0.7)
                Spacer()
                NavigationLink {
                    MemorySearchView(onDeletePlan: { await deleteSaved($0) },
                                     onOpenFinance: { selection = 2 })
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 19, weight: .semibold))
                }
                .accessibilityLabel("Search saved memories")
            }
            .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR LIFE, IN FOCUS")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.74))
                Text("What's next,\nall in one place.")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Important moments, receipts and renewal dates—organized privately on your iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(LinearGradient(colors: [RemorrowStyle.violet, RemorrowStyle.deepBlue],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .stroke(.white.opacity(0.13), lineWidth: 26)
                        .frame(width: 190, height: 190)
                        .offset(x: 88, y: -80)
                }
                .clipShape(RoundedRectangle(cornerRadius: 27))
        }
    }

    private var captureShortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick capture")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Spacer()
                Text("ON DEVICE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(RemorrowStyle.secondaryText)
            }
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    featureTile(
                        "From screenshot",
                        subtitle: "Find plans in chats",
                        symbol: "text.viewfinder",
                        colors: [Color(red: 0.40, green: 0.69, blue: 0.90), RemorrowStyle.deepBlue]
                    )
                }
                .buttonStyle(.plain)
                Button {
                    selection = 2
                } label: {
                    featureTile(
                        "Receipts & more",
                        subtitle: "Returns and renewals",
                        symbol: "receipt",
                        colors: [Color(red: 0.34, green: 0.52, blue: 0.74), Color(red: 0.05, green: 0.24, blue: 0.45)]
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func featureTile(_ title: String, subtitle: String,
                             symbol: String, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 38, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.86))
                    .frame(height: 61)
            }
            Spacer()
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .leading)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 21, style: .continuous)
        )
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                    Text("Your day")
                        .font(.system(size: 35, weight: .bold, design: .rounded))
                }
                Spacer()
                Text(String(agenda.count) + " ahead")
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
                if agenda.isEmpty {
                    Text("Nothing pressing.")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    Text("Capture a message or photo below. Your next important date will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                } else {
                    ForEach(Array(agenda.prefix(5))) { entry in
                        switch entry {
                        case .plan(let item):
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
                                        Text((item.dueAt < Date() ? "Overdue · " : "")
                                             + item.dueAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(item.dueAt < Date() ? .orange : RemorrowStyle.secondaryText)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(RemorrowStyle.secondaryText)
                                }
                            }
                            .buttonStyle(.plain)

                        case .shoppingReturn(let item):
                            Button {
                                selection = 2
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "shippingbox")
                                        .foregroundStyle(RemorrowStyle.violet)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Return " + item.itemName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RemorrowStyle.primaryText)
                                        Text((item.deadline < Date() ? "Overdue · " : "")
                                             + item.deadline.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(RemorrowStyle.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(RemorrowStyle.secondaryText)
                                }
                            }
                            .buttonStyle(.plain)
                        case .subscription(let item):
                            Button {
                                selection = 2
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(RemorrowStyle.violet)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(RemorrowStyle.primaryText)
                                        Text("Next charge · " + item.nextCharge.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(RemorrowStyle.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(RemorrowStyle.secondaryText)
                                }
                            }
                            .buttonStyle(.plain)
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
        returns.filter { !$0.isReturned && $0.hasConfirmedReturnDeadline && $0.deadline >= Date().addingTimeInterval(-7 * 24 * 60 * 60) }
    }

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    SectionEyebrow(title: "QUICK CAPTURE")
                    Text("Save what matters")
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

            if let pendingImageData, let image = UIImage(data: pendingImageData) {
                HStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .accessibilityLabel("Attached source photo")
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Photo attached")
                            .font(.subheadline.weight(.semibold))
                        Text("Saved with your plan after confirmation")
                            .font(.caption2)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }
                    Spacer(minLength: 0)
                    Button {
                        self.pendingImageData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(RemorrowStyle.secondaryText)
                            .font(.title3)
                    }
                    .accessibilityLabel("Remove attached photo")
                }
                .padding(11)
                .background(RemorrowStyle.canvas, in: RoundedRectangle(cornerRadius: 12))
            }

            Text("From Messages: long-press a message and copy it, then tap Paste & analyze. For supported apps, use Share → Remorrow.")
                .font(.system(size: 11))
                .foregroundStyle(RemorrowStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if savedCandidateCount > 0 && candidate != nil && !reviewPresented && activeReviewSource == draft {
                Button {
                    reviewPresented = true
                } label: {
                    Label("Resume the remaining suggestions", systemImage: "arrow.uturn.forward")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RemorrowStyle.violet)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .accessibilityIdentifier("resumeReview")
            }

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
                    HStack {
                        Text("My plans")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .tracking(-1)
                        Spacer()
                        NavigationLink {
                            MemorySearchView(onDeletePlan: { await deleteSaved($0) },
                                             onOpenFinance: { selection = 2 })
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title3.weight(.medium))
                        }
                        .accessibilityLabel("Search all saved memories")
                    }
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
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 15) {
                            Label("Mindful notifications", systemImage: "bell.badge")
                                .font(.headline)
                                .foregroundStyle(RemorrowStyle.violet)
                            Toggle("Show next item title in Home Screen widget", isOn: $showDetailsInWidgets)
                                .tint(RemorrowStyle.violet)
                            Text("Widgets show counts only by default. Turn this on to allow a saved title to appear on your Home Screen.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            Divider()
                            Toggle("Suggest earlier preparation alerts", isOn: $smartAlerts)
                                .tint(RemorrowStyle.violet)
                            Text("New reminders and events can receive an extra alert at a suggested time. Existing events are unchanged.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            Divider()
                            Toggle("Daily briefing reminder", isOn: $dailyBriefingEnabled)
                                .tint(RemorrowStyle.violet)
                            Picker("Morning hour", selection: $dailyBriefingHour) {
                                ForEach(6...12, id: \.self) { hour in
                                    Text(String(format: "%02d:00", hour)).tag(hour)
                                }
                            }
                            .disabled(!dailyBriefingEnabled)
                            Text("One generic daily notification. No private titles on the lock screen.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            if let notificationStatus {
                                Text(notificationStatus)
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                        }
                    }
                    .onChange(of: dailyBriefingEnabled) { _, _ in
                        Task { await configureDailyBriefing() }
                    }
                    .onChange(of: dailyBriefingHour) { _, _ in
                        if dailyBriefingEnabled { Task { await configureDailyBriefing() } }
                    }
                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("Siri & Shortcuts", systemImage: "mic")
                                .font(.headline)
                                .foregroundStyle(RemorrowStyle.violet)
                            Text("Find “Remember with Remorrow” in Apple's Shortcuts app. Choose text or connect a clipboard action, then open Remorrow to review it.")
                                .font(.subheadline)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            Text("The shortcut never reads Messages automatically.")
                                .font(.caption)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                        }
                    }
                    Button {
                        showingWelcome = true
                    } label: {
                        Label("How Remorrow works", systemImage: "book.closed")
                            .foregroundStyle(RemorrowStyle.violet)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 7)
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
    private func configureDailyBriefing() async {
        do {
            let configured = try await DailyBriefingScheduler().configure(
                enabled: dailyBriefingEnabled, hour: dailyBriefingHour)
            notificationStatus = configured
                ? (dailyBriefingEnabled ? "Daily briefing scheduled." : "Daily briefing disabled.")
                : "Notifications aren't authorized. Check iPhone Settings."
        } catch {
            notificationStatus = "Could not schedule the daily briefing."
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
        guard !importingShare && !reviewPresented && !showingWelcome && hasCompletedWelcome else { return }
        importingShare = true
        defer { importingShare = false }
        do {
            guard let pending = try SharedInbox.loadOldest() else { return }
            switch pending.payload.type {
            case "text":
                pendingImageData = nil
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
        pendingImageData = nil
        draft = copied
        selection = 0
        Task { await analyze() }
    }

    private func analyze() async {
        if !reviewPresented && savedCandidateCount > 0 && candidate != nil && activeReviewSource == draft {
            reviewPresented = true
            return
        }
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let input = ExtractionInput(text: draft, capturedAt: Date(),
                localeIdentifier: Locale.current.identifier, timeZoneIdentifier: TimeZone.current.identifier)
            let proposals = try await engine.extract(from: input)
            activeReviewSource = draft
            totalCandidates = max(1, proposals.count)
            reviewedCount = 0
            savedCandidateCount = 0
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
            } else {
                await analyze()
            }
        } catch {
            errorMessage = "Couldn't read that screenshot. Try a clearer one or type the details."
        }
        selectedPhoto = nil
    }

    @MainActor
    private func skipCurrentCandidate() {
        advanceAfterReview()
    }

    @MainActor
    private func advanceAfterReview() {
        reviewedCount += 1
        if !remainingCandidates.isEmpty {
            candidate = remainingCandidates.removeFirst()
            return
        }
        reviewPresented = false
        candidate = nil
        if savedCandidateCount > 0 {
            draft = ""
            pendingImageData = nil
            selectedPhoto = nil
            editorRevision += 1
            saveMessage = savedCandidateCount == 1
                ? "Plan saved to your iPhone."
                : String(savedCandidateCount) + " plans saved to your iPhone."
        }
    }

    private func matchingPlan(for proposal: ActionProposal) -> SavedAction? {
        PlanMatcher.bestMatch(title: proposal.title,
                              source: proposal.sourceEvidence,
                              kind: proposal.kind.rawValue,
                              candidates: saved)
    }

    @MainActor
    private func updateSaved(_ original: SavedAction, title: String,
                             date: Date, kind: ProposedActionKind) async throws {
        guard kind.rawValue == original.kind else { throw ScheduleFailure.invalidKind }
        try await scheduler.update(title: title, date: date, kind: original.kind, externalID: original.externalID)
        let oldTitle = original.title
        let oldDate = original.dueAt
        let oldSource = original.sourceText
        original.title = title
        original.dueAt = date
        original.sourceText = draft
        do {
            try modelContext.save()
        } catch {
            original.title = oldTitle
            original.dueAt = oldDate
            original.sourceText = oldSource
            // Best-effort compensating write. If this fails too, surface
            // the issue rather than claiming both copies are synchronized.
            do {
                try await scheduler.update(title: oldTitle, date: oldDate,
                                           kind: original.kind, externalID: original.externalID)
            } catch {
                errorMessage = "The Apple item changed but local history couldn't update. Check both records."
            }
            throw error
        }
        // Keep the original external identifier and attachment; never create a duplicate.
        savedCandidateCount += 1
        advanceAfterReview()
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
            modelContext.rollback()
            CaptureMediaStore.remove(named: item.attachmentName)
            errorMessage = "Saved to Apple \(kind == .calendarEvent ? "Calendar" : "Reminders"), but the local history update failed. Check the Apple app before retrying."
            reviewPresented = false
            draft = ""
            pendingImageData = nil
            selectedPhoto = nil
            editorRevision += 1
            return
        }
        savedCandidateCount += 1
        advanceAfterReview()
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
        .modelContainer(for: [SavedAction.self, ReturnItem.self, SubscriptionItem.self], inMemory: true)
}
