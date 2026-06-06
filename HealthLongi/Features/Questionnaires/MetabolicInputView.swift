import SwiftUI

struct MetabolicInputView: View {
    @Binding var bmi: Double
    @Binding var physicalActivityMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Metabolic Health Inputs")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Used for diabetes risk (FINDRISC subset). HealthKit data will supplement these where available.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("BMI: \(bmi, specifier: "%.1f")")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.textPrimary)
                Slider(value: $bmi, in: 18...40, step: 0.1)
                    .tint(NHSTheme.primaryBlue)
                HStack {
                    Text("18")
                    Spacer()
                    Text("40")
                }
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
            }
            .nhsCard()

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
    }
}

#Preview {
    MetabolicInputView(bmi: .constant(26.5), physicalActivityMinutes: .constant(60))
        .padding()
}
