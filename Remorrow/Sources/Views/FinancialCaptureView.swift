import SwiftUI
import PhotosUI
import UIKit

/// OCR makes a draft. No return policy or renewal date is invented or saved
/// until the user confirms the actual deadline/charge date.
struct FinancialCaptureView: View {
    let kind: FinancialDocumentKind
    let onSave: @MainActor (FinancialDocumentKind, String, String, Date, Double?, String, String, Data?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var imageData: Data?
    @State private var sourceText = ""
    @State private var name = ""
    @State private var merchant = ""
    @State private var date = Date().addingTimeInterval(24 * 60 * 60)
    @State private var confirmedDate = false
    @State private var detectedDate: Date?
    @State private var evidence: String?
    @State private var amount = ""
    @State private var frequency = "Monthly"
    @State private var isScanning = false
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 7) {
                        SectionEyebrow(title: kind == .receipt ? "RECEIPT CAPTURE" : "RENEWAL CAPTURE")
                        Text(kind == .receipt ? "Keep the receipt." : "Keep the renewal.")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("Photograph or choose a screenshot. Remorrow reads it privately and suggests the details below.")
                            .font(.subheadline)
                            .foregroundStyle(RemorrowStyle.secondaryText)
                    }

                    HStack(spacing: 12) {
                        Button {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showingCamera = true
                            } else {
                                error = "The camera isn't available. Choose a photo instead."
                            }
                        } label: {
                            captureButton("Take photo", icon: "camera.fill")
                        }
                        .buttonStyle(.plain)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            captureButton("Choose photo", icon: "photo.on.rectangle")
                        }
                        .buttonStyle(.plain)
                    }
                    .disabled(isScanning || isSaving)

                    if isScanning {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Reading the document on your iPhone…")
                                .font(.subheadline)
                        }
                    }

                    if let imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 275)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    self.imageData = nil
                                    sourceText = ""
                                    detectedDate = nil
                                    evidence = nil
                                    confirmedDate = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(.black.opacity(0.6), in: Circle())
                                }
                                .accessibilityLabel("Remove document image")
                                .padding(8)
                            }
                    }

                    RemorrowCard {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionEyebrow(title: "EDIT DETAILS")
                            VStack(alignment: .leading, spacing: 6) {
                                Text(kind == .receipt ? "Item" : "Subscription")
                                    .font(.caption.weight(.semibold))
                                TextField(kind == .receipt ? "e.g. Headphones" : "e.g. Music service", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Merchant or service")
                                    .font(.caption.weight(.semibold))
                                TextField("Name", text: $merchant)
                                    .textInputAutocapitalization(.words)
                                    .textFieldStyle(.roundedBorder)
                            }
                            if kind == .subscription {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Charge amount (optional)")
                                        .font(.caption.weight(.semibold))
                                    TextField("e.g. 12.99", text: $amount)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }
                                Picker("Renewal frequency", selection: $frequency) {
                                    ForEach(["Monthly", "Yearly", "Weekly", "Other"], id: \.self) { value in
                                        Text(value).tag(value)
                                    }
                                }
                            }
                            Divider()
                            Text(kind == .receipt ? "LAST ELIGIBLE RETURN DAY" : "NEXT CHARGE DATE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RemorrowStyle.secondaryText)
                            DatePicker("Verified date", selection: $date,
                                       in: Date()...,
                                       displayedComponents: [.date, .hourAndMinute])
                                .tint(RemorrowStyle.violet)
                            if let evidence {
                                Text("Possible date found: " + evidence)
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.violet)
                            } else {
                                Text(kind == .receipt
                                     ? "A purchase date is not the return deadline. Check the store's policy or receipt."
                                     : "A payment date may not be the next renewal date. Check your subscription terms.")
                                    .font(.caption)
                                    .foregroundStyle(RemorrowStyle.secondaryText)
                            }
                            Toggle(kind == .receipt
                                   ? "I verified the last return date"
                                   : "I verified the next charge date",
                                   isOn: $confirmedDate)
                                .font(.subheadline)
                                .tint(RemorrowStyle.violet)
                        }
                    }

                    if !sourceText.isEmpty {
                        DisclosureGroup("Recognized document text") {
                            Text(sourceText)
                                .font(.footnote)
                                .foregroundStyle(RemorrowStyle.secondaryText)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10)
                        }
                        .font(.subheadline.weight(.semibold))
                    }

                    RemorrowPrimaryButton(
                        title: kind == .receipt ? "Save receipt & return" : "Save subscription",
                        systemImage: "checkmark",
                        isBusy: isSaving
                    ) {
                        save()
                    }
                    .disabled(isScanning || isSaving || !confirmedDate ||
                              name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              date <= Date())
                    .opacity(confirmedDate ? 1 : 0.55)

                    Text("OCR suggestions never create a return or subscription without your confirmation. Your photo stays on this device.")
                        .font(.caption)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }
                .padding(22)
            }
            .background(RemorrowStyle.canvas.ignoresSafeArea())
            .navigationTitle(kind == .receipt ? "New receipt" : "New subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                LiveCameraView(onPhoto: { data in
                    showingCamera = false
                    Task { await scan(data) }
                }, onCancel: { showingCamera = false })
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, selected in
                guard let selected else { return }
                Task {
                    defer { selectedPhoto = nil }
                    do {
                        guard let data = try await selected.loadTransferable(type: Data.self) else {
                            error = "Couldn't load that image."
                            return
                        }
                        await scan(data)
                    } catch {
                        self.error = "Couldn't read this photo. Try another image."
                    }
                }
            }
            .alert("Couldn't complete that", isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
        }
    }

    private func captureButton(_ title: String, icon: String) -> some View {
        VStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(RemorrowStyle.violet)
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundStyle(RemorrowStyle.primaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 108)
        .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    @MainActor
    private func scan(_ data: Data) async {
        isScanning = true
        defer { isScanning = false }
        do {
            let text = try await ImageTextReader().recognize(data: data)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                error = "No readable words were found. Retake the photo with clearer text."
                return
            }
            imageData = data
            sourceText = text
            let result = FinancialDocumentParser.interpret(text, kind: kind)
            name = result.name
            merchant = result.merchant
            detectedDate = result.date
            evidence = result.dateEvidence
            if let detectedDate, detectedDate > Date() { date = detectedDate }
            if let amount = result.amount { self.amount = String(format: "%.2f", amount) }
            confirmedDate = false
        } catch {
            self.error = "The document couldn't be scanned. Try a clearer photo."
        }
    }

    private func save() {
        guard !isSaving && confirmedDate else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await onSave(
                    kind,
                    name.trimmingCharacters(in: .whitespacesAndNewlines),
                    merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                    date,
                    Double(amount.trimmingCharacters(in: .whitespacesAndNewlines)),
                    frequency,
                    sourceText,
                    imageData
                )
                dismiss()
            } catch {
                self.error = "Couldn't save this item. Please try again."
            }
        }
    }
}
