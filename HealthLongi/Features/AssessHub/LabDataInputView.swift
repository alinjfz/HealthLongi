import SwiftUI
import SwiftData

struct LabDataInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var cholesterol = ""
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var bloodSugar = ""
    @State private var hba1c = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Lipids") {
                    TextField("Total cholesterol (mmol/L)", text: $cholesterol)
                        .keyboardType(.decimalPad)
                }

                Section("Blood Pressure") {
                    TextField("Systolic (mmHg)", text: $systolic)
                        .keyboardType(.numberPad)
                    TextField("Diastolic (mmHg)", text: $diastolic)
                        .keyboardType(.numberPad)
                }

                Section("Glucose") {
                    TextField("Blood sugar (mmol/L)", text: $bloodSugar)
                        .keyboardType(.decimalPad)
                    TextField("HbA1c (%)", text: $hba1c)
                        .keyboardType(.decimalPad)
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
        }
    }

    private func loadExisting() {
        guard let labs = profile.labResults else { return }
        if let value = labs.cholesterol { cholesterol = format(value) }
        if let value = labs.bloodPressureSystolic { systolic = "\(value)" }
        if let value = labs.bloodPressureDiastolic { diastolic = "\(value)" }
        if let value = labs.bloodSugar { bloodSugar = format(value) }
        if let value = labs.hba1c { hba1c = format(value) }
    }

    private func save() {
        let parsedCholesterol = parseDouble(cholesterol)
        let parsedSystolic = parseInt(systolic)
        let parsedDiastolic = parseInt(diastolic)
        let parsedBloodSugar = parseDouble(bloodSugar)
        let parsedHbA1c = parseDouble(hba1c)

        if cholesterol.isEmpty == false && parsedCholesterol == nil
            || systolic.isEmpty == false && parsedSystolic == nil
            || diastolic.isEmpty == false && parsedDiastolic == nil
            || bloodSugar.isEmpty == false && parsedBloodSugar == nil
            || hba1c.isEmpty == false && parsedHbA1c == nil {
            errorMessage = "Please enter valid numbers for all filled fields."
            return
        }

        if [cholesterol, systolic, diastolic, bloodSugar, hba1c].allSatisfy(\.isEmpty) {
            errorMessage = "Enter at least one lab value to save."
            return
        }

        profile.labResults = LabResults(
            cholesterol: parsedCholesterol,
            bloodPressureSystolic: parsedSystolic,
            bloodPressureDiastolic: parsedDiastolic,
            bloodSugar: parsedBloodSugar,
            hba1c: parsedHbA1c,
            lastUpdated: .now
        )
        try? modelContext.save()
        dismiss()
    }

    private func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func parseInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
