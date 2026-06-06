import SwiftUI
import SwiftData

struct LabDataInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    // MARK: - Lipids
    @State private var cholesterol = ""
    @State private var ldlCholesterol = ""
    @State private var hdlCholesterol = ""
    @State private var triglycerides = ""

    // MARK: - Blood Pressure
    @State private var systolic = ""
    @State private var diastolic = ""

    // MARK: - Glucose & Diabetes
    @State private var bloodSugar = ""
    @State private var hba1c = ""

    // MARK: - Kidney Function
    @State private var egfr = ""
    @State private var creatinine = ""

    // MARK: - Thyroid
    @State private var tsh = ""

    // MARK: - Other
    @State private var vitaminD = ""
    @State private var crp = ""
    @State private var waistCircumference = ""

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Total cholesterol (mmol/L)", text: $cholesterol)
                        .keyboardType(.decimalPad)
                    TextField("LDL cholesterol (mmol/L)", text: $ldlCholesterol)
                        .keyboardType(.decimalPad)
                    TextField("HDL cholesterol (mmol/L)", text: $hdlCholesterol)
                        .keyboardType(.decimalPad)
                    TextField("Triglycerides (mmol/L)", text: $triglycerides)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Lipids")
                } footer: {
                    Text("NHS recommends total cholesterol below 5.0 mmol/L.")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section {
                    TextField("Systolic (mmHg)", text: $systolic)
                        .keyboardType(.numberPad)
                    TextField("Diastolic (mmHg)", text: $diastolic)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Blood Pressure")
                } footer: {
                    Text("Normal range is below 120/80 mmHg (NHS).")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section {
                    TextField("Fasting blood sugar (mmol/L)", text: $bloodSugar)
                        .keyboardType(.decimalPad)
                    TextField("HbA1c (%)", text: $hba1c)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Glucose & Diabetes")
                } footer: {
                    Text("Normal fasting glucose: 3.9–5.5 mmol/L. HbA1c below 6.0% is non-diabetic.")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section {
                    TextField("eGFR (mL/min/1.73m²)", text: $egfr)
                        .keyboardType(.decimalPad)
                    TextField("Creatinine (µmol/L)", text: $creatinine)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Kidney Function")
                } footer: {
                    Text("eGFR above 90 is considered normal. Used to assess chronic kidney disease risk.")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section {
                    TextField("TSH (mIU/L)", text: $tsh)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Thyroid")
                } footer: {
                    Text("Normal TSH range: 0.4–4.0 mIU/L. Abnormal levels may indicate thyroid dysfunction.")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section {
                    TextField("25-OH Vitamin D (nmol/L)", text: $vitaminD)
                        .keyboardType(.decimalPad)
                    TextField("CRP (mg/L)", text: $crp)
                        .keyboardType(.decimalPad)
                    TextField("Waist circumference (cm)", text: $waistCircumference)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Other Markers")
                } footer: {
                    Text("Vitamin D below 25 nmol/L is deficient. CRP above 10 mg/L may indicate inflammation. Waist circumference is linked to cardiovascular and metabolic risk.")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
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
        if let value = labs.ldlCholesterol { ldlCholesterol = format(value) }
        if let value = labs.hdlCholesterol { hdlCholesterol = format(value) }
        if let value = labs.triglycerides { triglycerides = format(value) }
        if let value = labs.bloodPressureSystolic { systolic = "\(value)" }
        if let value = labs.bloodPressureDiastolic { diastolic = "\(value)" }
        if let value = labs.bloodSugar { bloodSugar = format(value) }
        if let value = labs.hba1c { hba1c = format(value) }
        if let value = labs.egfr { egfr = format(value) }
        if let value = labs.creatinine { creatinine = format(value) }
        if let value = labs.tsh { tsh = format(value) }
        if let value = labs.vitaminD { vitaminD = format(value) }
        if let value = labs.crp { crp = format(value) }
        if let value = labs.waistCircumference { waistCircumference = format(value) }
    }

    private func save() {
        let parsedCholesterol = parseDouble(cholesterol)
        let parsedLDL = parseDouble(ldlCholesterol)
        let parsedHDL = parseDouble(hdlCholesterol)
        let parsedTriglycerides = parseDouble(triglycerides)
        let parsedSystolic = parseInt(systolic)
        let parsedDiastolic = parseInt(diastolic)
        let parsedBloodSugar = parseDouble(bloodSugar)
        let parsedHbA1c = parseDouble(hba1c)
        let parsedEGFR = parseDouble(egfr)
        let parsedCreatinine = parseDouble(creatinine)
        let parsedTSH = parseDouble(tsh)
        let parsedVitaminD = parseDouble(vitaminD)
        let parsedCRP = parseDouble(crp)
        let parsedWaist = parseDouble(waistCircumference)

        // Validate: if a field is non-empty, it must parse as a valid number
        let textFields: [(String, Double?)] = [
            (cholesterol, parsedCholesterol), (ldlCholesterol, parsedLDL),
            (hdlCholesterol, parsedHDL), (triglycerides, parsedTriglycerides),
            (bloodSugar, parsedBloodSugar), (hba1c, parsedHbA1c),
            (egfr, parsedEGFR), (creatinine, parsedCreatinine),
            (tsh, parsedTSH), (vitaminD, parsedVitaminD),
            (crp, parsedCRP), (waistCircumference, parsedWaist)
        ]
        let intFields: [(String, Int?)] = [
            (systolic, parsedSystolic), (diastolic, parsedDiastolic)
        ]

        for (text, value) in textFields where !text.isEmpty && value == nil {
            errorMessage = "Please enter valid numbers for all filled fields."
            return
        }
        for (text, value) in intFields where !text.isEmpty && value == nil {
            errorMessage = "Please enter valid numbers for all filled fields."
            return
        }

        let allTexts = textFields.map(\.0) + intFields.map(\.0)
        if allTexts.allSatisfy(\.isEmpty) {
            errorMessage = "Enter at least one lab value to save."
            return
        }

        profile.labResults = LabResults(
            cholesterol: parsedCholesterol,
            ldlCholesterol: parsedLDL,
            hdlCholesterol: parsedHDL,
            triglycerides: parsedTriglycerides,
            bloodPressureSystolic: parsedSystolic,
            bloodPressureDiastolic: parsedDiastolic,
            bloodSugar: parsedBloodSugar,
            hba1c: parsedHbA1c,
            egfr: parsedEGFR,
            creatinine: parsedCreatinine,
            tsh: parsedTSH,
            vitaminD: parsedVitaminD,
            crp: parsedCRP,
            waistCircumference: parsedWaist,
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
