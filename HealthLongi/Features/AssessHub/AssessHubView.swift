import SwiftUI
import SwiftData

struct AssessHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = AssessmentHubViewModel(profile: nil)
    @State private var activeSheet: AssessSheet?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header

                    sectionHeader("Questionnaires")
                    AssessmentCard(
                        title: "PHQ-9",
                        subtitle: "Depression screening (9 questions)",
                        icon: "brain.head.profile",
                        isCompleted: viewModel.phq9Completed
                    ) { activeSheet = .phq9 }

                    AssessmentCard(
                        title: "GAD-7",
                        subtitle: "Anxiety screening (7 questions)",
                        icon: "waveform.path.ecg",
                        isCompleted: viewModel.gad7Completed
                    ) { activeSheet = .gad7 }

                    AssessmentCard(
                        title: "Metabolic Inputs",
                        subtitle: "BMI and weekly activity",
                        icon: "figure.walk",
                        isCompleted: viewModel.metabolicCompleted
                    ) { activeSheet = .metabolic }

                    sectionHeader("Lab & Calculators")
                    AssessmentCard(
                        title: "Lab Results",
                        subtitle: "Cholesterol, BP, blood sugar, HbA1c",
                        icon: "cross.vial.fill",
                        isCompleted: viewModel.labDataCompleted
                    ) {
                        if let profile { activeSheet = .labData(profile) }
                    }

                    AssessmentCard(
                        title: "BMI Calculator",
                        subtitle: "Calculate body mass index",
                        icon: "scalemass.fill",
                        isCompleted: false
                    ) { activeSheet = .bmiCalculator }

                    sectionHeader("HealthKit Data")
                    healthKitCard(
                        title: "Daily Steps",
                        subtitle: "Weekly average from Apple Health",
                        icon: "figure.walk"
                    )
                    healthKitCard(
                        title: "Resting Heart Rate",
                        subtitle: "Weekly average from Apple Health",
                        icon: "heart.fill"
                    )
                    healthKitCard(
                        title: "Sleep",
                        subtitle: "Average hours from Apple Health",
                        icon: "bed.double.fill"
                    )
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Assess")
            .onAppear { refreshViewModel() }
            .onChange(of: profiles.first?.phq9Score) { refreshViewModel() }
            .onChange(of: profiles.first?.gad7Score) { refreshViewModel() }
            .onChange(of: profiles.first?.bmi) { refreshViewModel() }
            .onChange(of: profiles.first?.physicalActivityMinutes) { refreshViewModel() }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .phq9:
                    PHQ9SheetView(profile: profile, modelContext: modelContext) {
                        refreshViewModel()
                    }
                case .gad7:
                    GAD7SheetView(profile: profile, modelContext: modelContext) {
                        refreshViewModel()
                    }
                case .metabolic:
                    MetabolicSheetView(profile: profile, modelContext: modelContext) {
                        refreshViewModel()
                    }
                case .labData(let userProfile):
                    LabDataInputView(profile: userProfile)
                case .bmiCalculator:
                    BMICalculatorView()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Assessments")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)
            Text("Complete assessments at your own pace. All data stays on your device.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(NHSTheme.primaryBlue)
            .padding(.top, 4)
    }

    private func healthKitCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(NHSTheme.primaryBlue)
                .frame(width: 44, height: 44)
                .background(NHSTheme.primaryBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(NHSTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "applewatch")
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private func refreshViewModel() {
        viewModel = AssessmentHubViewModel(profile: profile)
    }
}

private enum AssessSheet: Identifiable {
    case phq9
    case gad7
    case metabolic
    case labData(UserProfile)
    case bmiCalculator

    var id: String {
        switch self {
        case .phq9: "phq9"
        case .gad7: "gad7"
        case .metabolic: "metabolic"
        case .labData(let profile): "lab-\(profile.persistentModelID)"
        case .bmiCalculator: "bmi"
        }
    }
}

// MARK: - Questionnaire Sheets

private struct PHQ9SheetView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?
    let modelContext: ModelContext
    var onSave: () -> Void

    @State private var answers: [Int?] = Array(repeating: nil, count: 9)

    private var isComplete: Bool { answers.allSatisfy { $0 != nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                PHQ9View(answers: $answers)
                    .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("PHQ-9")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isComplete)
                }
            }
        }
    }

    private func save() {
        guard let profile, isComplete else { return }
        profile.phq9Score = answers.compactMap { $0 }.reduce(0, +)
        try? modelContext.save()
        onSave()
        dismiss()
    }
}

private struct GAD7SheetView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?
    let modelContext: ModelContext
    var onSave: () -> Void

    @State private var answers: [Int?] = Array(repeating: nil, count: 7)

    private var isComplete: Bool { answers.allSatisfy { $0 != nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                GAD7View(answers: $answers)
                    .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("GAD-7")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isComplete)
                }
            }
        }
    }

    private func save() {
        guard let profile, isComplete else { return }
        profile.gad7Score = answers.compactMap { $0 }.reduce(0, +)
        try? modelContext.save()
        onSave()
        dismiss()
    }
}

private struct MetabolicSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?
    let modelContext: ModelContext
    var onSave: () -> Void

    @State private var bmi = 25.0
    @State private var activityMinutes = 60

    var body: some View {
        NavigationStack {
            ScrollView {
                MetabolicInputView(bmi: $bmi, physicalActivityMinutes: $activityMinutes)
                    .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Metabolic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                if let profile {
                    bmi = profile.bmi ?? 25.0
                    activityMinutes = profile.physicalActivityMinutes ?? 60
                }
            }
        }
    }

    private func save() {
        guard let profile else { return }
        profile.bmi = bmi
        profile.physicalActivityMinutes = activityMinutes
        try? modelContext.save()
        onSave()
        dismiss()
    }
}

#Preview {
    AssessHubView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
