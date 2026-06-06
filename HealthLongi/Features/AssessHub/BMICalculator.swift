import SwiftUI

struct BMICalculatorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var weightText = ""
    @State private var heightText = ""
    @State private var result: BMICalculatorResult?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Calculate your Body Mass Index")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (kg)")
                            .font(.headline)
                        TextField("e.g. 70", text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .nhsCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height (cm)")
                            .font(.headline)
                        TextField("e.g. 175", text: $heightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .nhsCard()

                    Button("Calculate") {
                        calculate()
                    }
                    .buttonStyle(NHSPrimaryButtonStyle())

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if let result {
                        resultCard(result)
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("BMI Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func calculate() {
        errorMessage = nil
        result = nil

        guard let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")),
              let height = Double(heightText.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Enter valid weight and height values."
            return
        }

        guard let calculated = BMICalculatorResult.calculate(weightKg: weight, heightCm: height) else {
            errorMessage = "Weight and height must be greater than zero."
            return
        }

        result = calculated
    }

    @ViewBuilder
    private func resultCard(_ result: BMICalculatorResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your BMI")
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)

            Text(String(format: "%.1f", result.bmi))
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(result.category.color)

            Text(result.category.displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(result.category.color)

            Text(bmiMessage(for: result.category))
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private func bmiMessage(for category: BMICategory) -> String {
        switch category {
        case .underweight:
            "Your BMI is below the healthy range. Consider speaking with your GP about nutrition."
        case .normal:
            "Your BMI is within the healthy range. Keep up balanced eating and regular activity."
        case .overweight:
            "Your BMI is above the healthy range. Small lifestyle changes can help reduce health risks."
        case .obese:
            "Your BMI indicates obesity. NHS resources can help you plan sustainable changes."
        }
    }
}

#Preview {
    BMICalculatorView()
}
