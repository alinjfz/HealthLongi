import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct LabDataInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var selectedPanel: LabPanel = .basic
    @State private var fieldTexts: [LabBiomarker: String] = [:]
    @State private var errorMessage: String?
    @State private var importErrorMessage: String?
    @State private var isImporting = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPDFImporter = false
    @State private var parsedForReview: [LabReportOCRService.ParsedValue]?
    @State private var showReviewSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Lab values stay on your device and are never sent to AI.")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Scan lab report photo", systemImage: "doc.viewfinder")
                    }
                    .disabled(isImporting)

                    Button {
                        showPDFImporter = true
                    } label: {
                        Label("Upload PDF report", systemImage: "doc.fill")
                    }
                    .disabled(isImporting)

                    if isImporting {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Reading report on device…")
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                    }

                    if let importErrorMessage {
                        Text(importErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Import")
                } footer: {
                    Text("Photos and PDFs are processed on your device using OCR. Nothing is uploaded.")
                        .font(.caption2)
                }

                Section {
                    Picker("Panel", selection: $selectedPanel) {
                        ForEach(LabPanel.allCases) { panel in
                            Text(panel.title).tag(panel)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                let grouped = LabBiomarker.forPanel(selectedPanel, sex: profile.sex)
                ForEach(LabCategory.allCases.filter { grouped[$0] != nil }) { category in
                    if let markers = grouped[category], !markers.isEmpty {
                        Section {
                            ForEach(markers) { marker in
                                TextField("\(marker.label) (\(marker.unit))", text: binding(for: marker))
                                    .keyboardType(marker.isIntegerField ? .numberPad : .decimalPad)
                            }
                        } header: {
                            Text(category.title)
                        } footer: {
                            if let first = markers.first {
                                Text(first.hint)
                                    .font(.caption2)
                                    .foregroundStyle(NHSTheme.textSecondary)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Lab Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { loadExisting() }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task { await importPhoto(newItem) }
            }
            .fileImporter(
                isPresented: $showPDFImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importPDF(url)
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showReviewSheet, onDismiss: { parsedForReview = nil }) {
                if let parsedForReview {
                    LabReportReviewSheet(parsedValues: parsedForReview) { values in
                        applyParsedValues(values)
                    }
                }
            }
        }
    }

    private func binding(for marker: LabBiomarker) -> Binding<String> {
        Binding(
            get: { fieldTexts[marker, default: ""] },
            set: { fieldTexts[marker] = $0 }
        )
    }

    private func loadExisting() {
        guard let labs = profile.labResults else { return }
        for marker in LabBiomarker.allCases {
            if let value = LabBiomarkerIO.stringValue(marker, from: labs) {
                fieldTexts[marker] = value
            }
        }
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        isImporting = true
        importErrorMessage = nil
        defer {
            isImporting = false
            selectedPhoto = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                importErrorMessage = "Could not load the selected image."
                return
            }
            let text = try await LabReportImportService.recognizeText(from: image)
            presentParsed(LabReportImportService.parseImportedText(text))
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func importPDF(_ url: URL) {
        isImporting = true
        importErrorMessage = nil
        defer { isImporting = false }

        do {
            let text = try LabReportImportService.extractText(from: url)
            presentParsed(LabReportImportService.parseImportedText(text))
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func presentParsed(_ values: [LabReportOCRService.ParsedValue]) {
        if values.isEmpty {
            importErrorMessage = "No recognised biomarkers found. Try a clearer photo or enter values manually."
            return
        }
        parsedForReview = values
        showReviewSheet = true
    }

    private func applyParsedValues(_ values: [LabReportOCRService.ParsedValue]) {
        for item in values {
            if item.marker.isIntegerField {
                fieldTexts[item.marker] = "\(Int(item.value))"
            } else {
                fieldTexts[item.marker] = String(format: "%.2f", item.value)
            }
        }
        importErrorMessage = nil
    }

    private func save() {
        var labs = profile.labResults ?? LabResults(lastUpdated: .now)
        var hasValue = false

        for marker in LabBiomarker.allCases {
            let text = fieldTexts[marker, default: ""].trimmingCharacters(in: .whitespaces)
            if text.isEmpty {
                LabBiomarkerIO.setValue(marker, value: nil, on: &labs)
                continue
            }
            if marker.isIntegerField {
                guard let intVal = Int(text) else {
                    errorMessage = "Please enter valid numbers for all filled fields."
                    return
                }
                LabBiomarkerIO.setValue(marker, value: Double(intVal), on: &labs)
            } else {
                guard let doubleVal = Double(text.replacingOccurrences(of: ",", with: ".")) else {
                    errorMessage = "Please enter valid numbers for all filled fields."
                    return
                }
                LabBiomarkerIO.setValue(marker, value: doubleVal, on: &labs)
            }
            hasValue = true
        }

        if !hasValue {
            errorMessage = "Enter at least one lab value to save."
            return
        }

        labs.lastUpdated = .now
        profile.labResults = labs
        errorMessage = nil
        try? modelContext.save()
        dismiss()
    }
}
