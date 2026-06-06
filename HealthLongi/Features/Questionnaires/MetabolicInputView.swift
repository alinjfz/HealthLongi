import SwiftUI

struct MetabolicInputView: View {
    @Binding var bmi: Double?
    @Binding var weightKg: Double?
    @Binding var heightCm: Double?
    @Binding var physicalActivityMinutes: Int

    let healthSnapshot: WeeklyHealthSnapshot

    @State private var weightUnit: WeightUnit = .kg
    @State private var heightUnit: HeightUnit = .cm
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var feetText = ""
    @State private var inchesText = ""

    private var hkWeight: Double? { healthSnapshot.bodyMass }
    private var hkHeightCm: Double? { healthSnapshot.height.map { $0 * 100 } }
    private var hasFullHealthKit: Bool { hkWeight != nil && hkHeightCm != nil }

    private var calculatedBMI: Double? {
        if hasFullHealthKit, let w = hkWeight, let h = hkHeightCm {
            return BMICalculatorResult.calculate(weightKg: w, heightCm: h)?.bmi
        }
        guard let w = parsedWeightKg, let h = parsedHeightCm, w > 0, h > 0 else { return nil }
        return BMICalculatorResult.calculate(weightKg: w, heightCm: h)?.bmi
    }

    private var parsedWeightKg: Double? {
        if hasFullHealthKit { return hkWeight }
        if let value = Double(weightText.replacingOccurrences(of: ",", with: ".")), value > 0 {
            return weightUnit.toKg(value)
        }
        return hkWeight
    }

    private var parsedHeightCm: Double? {
        if hasFullHealthKit { return hkHeightCm }
        switch heightUnit {
        case .cm:
            if let value = Double(heightText.replacingOccurrences(of: ",", with: ".")), value > 0 {
                return value
            }
            return hkHeightCm
        case .ftIn:
            guard let ft = Int(feetText), let inch = Int(inchesText), ft >= 0, inch >= 0 else {
                return hkHeightCm
            }
            let cm = HeightUnit.toCm(feet: ft, inches: inch)
            return cm > 0 ? cm : hkHeightCm
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Metabolic Health")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("We use your weight and height to estimate BMI for metabolic risk. Data stays on your device.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            bmiSection
            bodyMetricsSection
            activitySection
        }
        .onAppear { loadExisting(); syncBindings() }
        .onChange(of: calculatedBMI) { _, _ in syncBindings() }
        .onChange(of: weightText) { _, _ in syncBindings() }
        .onChange(of: heightText) { _, _ in syncBindings() }
        .onChange(of: feetText) { _, _ in syncBindings() }
        .onChange(of: inchesText) { _, _ in syncBindings() }
        .onChange(of: weightUnit) { _, _ in syncBindings() }
        .onChange(of: heightUnit) { _, _ in syncBindings() }
        .onChange(of: healthSnapshot.bodyMass) { _, _ in syncBindings() }
        .onChange(of: healthSnapshot.height) { _, _ in syncBindings() }
    }

    private func syncBindings() {
        bmi = calculatedBMI
        if hasFullHealthKit {
            weightKg = hkWeight
            heightCm = hkHeightCm
        } else {
            weightKg = parsedWeightKg
            heightCm = parsedHeightCm
        }
    }

    @ViewBuilder
    private var bmiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your BMI")
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)

            if let bmiValue = calculatedBMI {
                let category = BMICategory.from(bmi: bmiValue)
                HStack {
                    Text(String(format: "%.1f", bmiValue))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(category.color)
                    VStack(alignment: .leading) {
                        Text(category.displayName)
                            .font(.subheadline.weight(.semibold))
                        if hasFullHealthKit {
                            Label("From Apple Health", systemImage: "heart.text.square")
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                    }
                }
            } else {
                Text("Enter your weight and height below to calculate BMI.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
    }

    @ViewBuilder
    private var bodyMetricsSection: some View {
        if hasFullHealthKit {
            VStack(alignment: .leading, spacing: 8) {
                Text("Body measurements")
                    .font(.headline)
                LabeledContent("Weight", value: String(format: "%.1f kg", hkWeight ?? 0))
                LabeledContent("Height", value: String(format: "%.0f cm", hkHeightCm ?? 0))
            }
            .nhsCard()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Body measurements")
                    .font(.headline)

                if hkWeight != nil || hkHeightCm != nil {
                    Text("Some values were prefilled from Apple Health.")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                HStack {
                    Text("Weight")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Picker("Weight unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                TextField(weightUnit == .kg ? "e.g. 70" : "e.g. 154", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        if weightText.isEmpty, let w = weightKg ?? hkWeight {
                            weightText = String(format: "%.1f", weightUnit.fromKg(w))
                        }
                    }

                HStack {
                    Text("Height")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Picker("Height unit", selection: $heightUnit) {
                        ForEach(HeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                if heightUnit == .cm {
                    TextField("e.g. 175", text: $heightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            if heightText.isEmpty, let h = heightCm ?? hkHeightCm {
                                heightText = String(format: "%.0f", h)
                            }
                        }
                } else {
                    HStack {
                        TextField("ft", text: $feetText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField("in", text: $inchesText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .onAppear {
                        if feetText.isEmpty, let h = heightCm ?? hkHeightCm {
                            let parts = HeightUnit.fromCm(h)
                            feetText = "\(parts.feet)"
                            inchesText = "\(parts.inches)"
                        }
                    }
                }
            }
            .nhsCard()
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly physical activity")
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)
            Stepper("\(physicalActivityMinutes) minutes", value: $physicalActivityMinutes, in: 0...600, step: 15)
            Text("Moderate activity such as brisk walking")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private func loadExisting() {
        if let w = weightKg ?? hkWeight {
            weightText = String(format: "%.1f", weightUnit.fromKg(w))
        }
        if let h = heightCm ?? hkHeightCm {
            heightText = String(format: "%.0f", h)
            let parts = HeightUnit.fromCm(h)
            feetText = "\(parts.feet)"
            inchesText = "\(parts.inches)"
        }
        bmi = calculatedBMI ?? bmi
    }
}

#Preview {
    MetabolicInputView(
        bmi: .constant(nil),
        weightKg: .constant(nil),
        heightCm: .constant(nil),
        physicalActivityMinutes: .constant(60),
        healthSnapshot: WeeklyHealthSnapshot(
            averageDailySteps: 5000,
            priorAverageDailySteps: 5000,
            bodyMass: 75,
            height: 1.75,
            fetchedAt: .now
        )
    )
    .padding()
}
