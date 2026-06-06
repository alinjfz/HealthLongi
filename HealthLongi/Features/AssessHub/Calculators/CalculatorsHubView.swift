import SwiftUI

struct CalculatorsHubView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?
    let healthSnapshot: WeeklyHealthSnapshot

    @State private var selectedCalculator: CalculatorKind?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(CalculatorKind.allCases) { kind in
                        Button {
                            selectedCalculator = kind
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: kind.icon)
                                    .font(.title2)
                                    .foregroundStyle(NHSTheme.primaryBlue)
                                    .frame(width: 44, height: 44)
                                    .background(NHSTheme.primaryBlue.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(kind.title)
                                        .font(.headline)
                                        .foregroundStyle(NHSTheme.textPrimary)
                                    Text(kind.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(NHSTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(NHSTheme.textSecondary)
                            }
                            .nhsCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Calculators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedCalculator) { kind in
                calculatorView(for: kind)
            }
        }
    }

    @ViewBuilder
    private func calculatorView(for kind: CalculatorKind) -> some View {
        switch kind {
        case .waistHeight: WaistHeightCalculatorView(profile: profile, snapshot: healthSnapshot)
        case .idealWeight: IdealWeightCalculatorView(profile: profile, snapshot: healthSnapshot)
        case .calories: CalorieCalculatorView(profile: profile, snapshot: healthSnapshot)
        case .heartRateZones: HeartRateZoneCalculatorView(profile: profile)
        case .water: WaterIntakeCalculatorView(profile: profile, snapshot: healthSnapshot)
        case .alcohol: AlcoholUnitsCalculatorView()
        case .bloodPressure: BloodPressureCalculatorView(profile: profile)
        case .diabetesRisk: DiabetesRiskCalculatorView(profile: profile, snapshot: healthSnapshot)
        }
    }
}

enum CalculatorKind: String, CaseIterable, Identifiable {
    case waistHeight, idealWeight, calories, heartRateZones, water, alcohol, bloodPressure, diabetesRisk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waistHeight: "Waist-to-Height Ratio"
        case .idealWeight: "Healthy Weight Range"
        case .calories: "Daily Calories"
        case .heartRateZones: "Heart Rate Zones"
        case .water: "Water Intake"
        case .alcohol: "Alcohol Units"
        case .bloodPressure: "Blood Pressure Check"
        case .diabetesRisk: "Diabetes Risk"
        }
    }

    var subtitle: String {
        switch self {
        case .waistHeight: "Simple shape measure"
        case .idealWeight: "BMI 18.5–24.9 range"
        case .calories: "Estimated daily needs"
        case .heartRateZones: "Exercise intensity"
        case .water: "Hydration estimate"
        case .alcohol: "NHS units calculator"
        case .bloodPressure: "Category checker"
        case .diabetesRisk: "FINDRISC-style estimate"
        }
    }

    var icon: String {
        switch self {
        case .waistHeight: "ruler"
        case .idealWeight: "scalemass"
        case .calories: "flame"
        case .heartRateZones: "heart.fill"
        case .water: "drop.fill"
        case .alcohol: "wineglass"
        case .bloodPressure: "waveform.path.ecg"
        case .diabetesRisk: "chart.line.uptrend.xyaxis"
        }
    }
}

struct CalculatorResultCard: View {
    let title: String
    let message: String
    let color: Color
    var tip: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textPrimary)
            if let tip {
                Text(tip)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }
}

struct CalculatorSheetContainer<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
