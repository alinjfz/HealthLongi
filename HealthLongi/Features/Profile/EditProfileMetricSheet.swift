import SwiftUI
import SwiftData

struct EditProfileMetricSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let metric: ProfileHealthMetric
    let profile: UserProfile
    let onSave: () -> Void

    @State private var textValue = ""
    @State private var dateValue = Date()
    @State private var sex: Sex = .female
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Add a value for \(metric.title.lowercased()). It will be used when Apple Health does not provide this data.")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)

                    inputSection

                    if metric.source == .manual {
                        Button("Remove manual value") {
                            removeValue()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Save") { save() }
                        .buttonStyle(NHSPrimaryButtonStyle())
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle(metric.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadInitialValues() }
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch metric.key {
            case .dateOfBirth:
                DatePicker("Date of birth", selection: $dateValue, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            case .sex:
                Picker("Sex at birth", selection: $sex) {
                    ForEach(Sex.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            default:
                TextField(placeholder, text: $textValue)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .nhsCard()
    }

    private var placeholder: String {
        switch metric.key {
        case .dailySteps: "Average daily steps"
        case .walkingDistance: "Kilometres per day"
        case .activeEnergy: "Kilocalories per day"
        case .mindfulMinutes: "Minutes per day"
        case .physicalActivity: "Minutes per week"
        case .restingHeartRate: "Beats per minute"
        case .heartRateVariability: "Milliseconds"
        case .oxygenSaturation: "Percentage"
        case .bodyMass: "Kilograms"
        case .height: "Centimetres"
        case .bmi: "BMI value"
        case .bodyFat: "Body fat percentage"
        case .sleep: "Hours per night"
        default: "Enter value"
        }
    }

    private var keyboardType: UIKeyboardType {
        switch metric.key {
        case .dailySteps, .physicalActivity:
            .numberPad
        default:
            .decimalPad
        }
    }

    private func loadInitialValues() {
        switch metric.key {
        case .dateOfBirth:
            dateValue = profile.dateOfBirth
        case .sex:
            sex = profile.sex
        default:
            textValue = metric.value == "—" ? "" : numericSeed(from: metric.value)
        }
    }

    private func numericSeed(from value: String) -> String {
        value
            .replacingOccurrences(of: " km/day", with: "")
            .replacingOccurrences(of: " kcal/day", with: "")
            .replacingOccurrences(of: " min/day", with: "")
            .replacingOccurrences(of: " min/week", with: "")
            .replacingOccurrences(of: " bpm", with: "")
            .replacingOccurrences(of: " ms", with: "")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: " kg", with: "")
            .replacingOccurrences(of: " cm", with: "")
            .replacingOccurrences(of: " hrs/night", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let viewModel = ProfileHealthViewModel()

        switch metric.key {
        case .dateOfBirth:
            viewModel.saveManualValue(ISO8601DateFormatter.profileDate.string(from: dateValue), for: .dateOfBirth, profile: profile)
        case .sex:
            viewModel.saveManualValue(sex.rawValue, for: .sex, profile: profile)
        default:
            guard !textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please enter a value."
                return
            }

            let normalized: String
            if metric.key == .height, let cm = Double(textValue) {
                normalized = String(cm / 100.0)
            } else {
                normalized = textValue
            }

            guard Double(normalized) != nil || Int(normalized) != nil else {
                errorMessage = "Please enter a valid number."
                return
            }

            viewModel.saveManualValue(normalized, for: metric.key, profile: profile)
        }

        try? modelContext.save()
        onSave()
        dismiss()
    }

    private func removeValue() {
        ProfileHealthViewModel().clearManualValue(for: metric.key, profile: profile)
        try? modelContext.save()
        onSave()
        dismiss()
    }
}
