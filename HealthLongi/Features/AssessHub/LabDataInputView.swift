import SwiftUI
import SwiftData

struct LabDataInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var selectedPanel: LabPanel = .basic
    @State private var fieldTexts: [LabBiomarker: String] = [:]
    @State private var errorMessage: String?
    @State private var showScanComingSoon = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Lab values stay on your device and are never sent to AI.")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)

                    Button {
                        showScanComingSoon = true
                    } label: {
                        Label("Scan lab report (coming soon)", systemImage: "doc.viewfinder")
                    }
                    .disabled(true)
                    .foregroundStyle(NHSTheme.textSecondary)
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
            .alert("Coming soon", isPresented: $showScanComingSoon) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("On-device lab report scanning with Vision OCR will be available in a future update. Your images will never leave your device.")
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
