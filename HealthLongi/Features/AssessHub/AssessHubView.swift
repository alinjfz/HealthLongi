import SwiftUI
import SwiftData

struct AssessHubView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = AssessmentHubViewModel(profile: nil)
    @State private var activeSheet: AssessSheet?
    @State private var selectedHealthMetric: HealthKitMetric?
    @State private var healthSnapshot: WeeklyHealthSnapshot = .empty
    @State private var showGenetics = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header

                    sectionHeader("Questionnaires")
                    ForEach(QuestionnaireKind.allCases) { kind in
                        AssessmentCard(
                            title: kind.title,
                            subtitle: kind.subtitle,
                            icon: kind.icon,
                            isCompleted: completion(for: kind)
                        ) {
                            activeSheet = .questionnaire(kind)
                        }
                    }

                    AssessmentCard(
                        title: "Metabolic Inputs",
                        subtitle: "Weight, height, BMI and weekly activity",
                        icon: "figure.walk",
                        isCompleted: viewModel.metabolicCompleted
                    ) { activeSheet = .metabolic }

                    sectionHeader("Lab & Calculators")
                    AssessmentCard(
                        title: "Lab Results",
                        subtitle: "Basic & extensive biomarker panels",
                        icon: "cross.vial.fill",
                        isCompleted: viewModel.labDataCompleted
                    ) {
                        if let profile { activeSheet = .labData(profile) }
                    }

                    AssessmentCard(
                        title: "Health Calculators",
                        subtitle: "Calories, BP, diabetes risk & more",
                        icon: "function",
                        isCompleted: false
                    ) { activeSheet = .calculators }

                    sectionHeader("HealthKit Data")
                    ForEach(HealthKitMetric.allCases) { metric in
                        healthKitCard(metric: metric)
                    }

                    sectionHeader("Longevity")
                    GeneticsBetaCard(isCompleted: viewModel.geneticsCompleted) {
                        showGenetics = true
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Assess")
            .onAppear {
                refreshViewModel()
                Task { await refreshHealthKit() }
            }
            .onChange(of: profiles.first?.phq9Complete) { refreshViewModel() }
            .onChange(of: profiles.first?.gad7Complete) { refreshViewModel() }
            .onChange(of: profiles.first?.who5Complete) { refreshViewModel() }
            .onChange(of: profiles.first?.bmi) { refreshViewModel() }
            .onChange(of: profiles.first?.physicalActivityMinutes) { refreshViewModel() }
            .sheet(item: $activeSheet, onDismiss: { refreshViewModel() }) { sheet in
                switch sheet {
                case .questionnaire(let kind):
                    QuestionnaireSheetView(kind: kind, profile: profile, modelContext: modelContext) {
                        refreshViewModel()
                    }
                case .metabolic:
                    MetabolicSheetView(profile: profile, modelContext: modelContext, healthSnapshot: healthSnapshot) {
                        refreshViewModel()
                    }
                case .labData(let userProfile):
                    LabDataInputView(profile: userProfile)
                case .calculators:
                    CalculatorsHubView(profile: profile, healthSnapshot: healthSnapshot)
                }
            }
            .sheet(item: $selectedHealthMetric) { metric in
                HealthKitDetailView(metric: metric, snapshot: healthSnapshot)
            }
            .sheet(isPresented: $showGenetics, onDismiss: { refreshViewModel() }) {
                if let profile {
                    GeneticsBetaFlowView(profile: profile)
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

    private func completion(for kind: QuestionnaireKind) -> Bool {
        switch kind {
        case .phq9: viewModel.phq9Completed
        case .gad7: viewModel.gad7Completed
        case .who5: viewModel.who5Completed
        case .pss10: viewModel.pss10Completed
        case .sleep: viewModel.sleepCompleted
        case .auditC: viewModel.auditCCompleted
        case .phq15: viewModel.phq15Completed
        }
    }

    private func healthKitCard(metric: HealthKitMetric) -> some View {
        Button {
            selectedHealthMetric = metric
        } label: {
            HStack(spacing: 16) {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundStyle(NHSTheme.primaryBlue)
                    .frame(width: 44, height: 44)
                    .background(NHSTheme.primaryBlue.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .font(.headline)
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text(metric.subtitle)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Spacer()

                Text(metric.shortDisplay(from: healthSnapshot))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NHSTheme.primaryBlue)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NHSTheme.textSecondary)
            }
            .nhsCard()
        }
        .buttonStyle(.plain)
    }

    private func refreshViewModel() {
        viewModel = AssessmentHubViewModel(profile: profile)
    }

    private func refreshHealthKit() async {
        do {
            try await dependencies.healthDataProvider.requestAuthorization()
            healthSnapshot = try await dependencies.healthDataProvider.fetchWeeklySnapshot()
        } catch {
            healthSnapshot = .empty
        }
    }
}

private enum AssessSheet: Identifiable {
    case questionnaire(QuestionnaireKind)
    case metabolic
    case labData(UserProfile)
    case calculators

    var id: String {
        switch self {
        case .questionnaire(let kind): "q-\(kind.rawValue)"
        case .metabolic: "metabolic"
        case .labData(let profile): "lab-\(profile.persistentModelID)"
        case .calculators: "calculators"
        }
    }
}

private struct MetabolicSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDependencies) private var dependencies
    let profile: UserProfile?
    let modelContext: ModelContext
    let healthSnapshot: WeeklyHealthSnapshot
    var onSave: () -> Void

    @State private var bmi: Double?
    @State private var weightKg: Double?
    @State private var heightCm: Double?
    @State private var activityMinutes = 60
    @State private var snapshot: WeeklyHealthSnapshot

    init(profile: UserProfile?, modelContext: ModelContext, healthSnapshot: WeeklyHealthSnapshot, onSave: @escaping () -> Void) {
        self.profile = profile
        self.modelContext = modelContext
        self.healthSnapshot = healthSnapshot
        self.onSave = onSave
        _snapshot = State(initialValue: healthSnapshot)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                MetabolicInputView(
                    bmi: $bmi,
                    weightKg: $weightKg,
                    heightCm: $heightCm,
                    physicalActivityMinutes: $activityMinutes,
                    healthSnapshot: snapshot
                )
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
                        .disabled(bmi == nil)
                }
            }
            .task {
                await refreshSnapshot()
            }
            .onAppear {
                if let profile {
                    bmi = profile.bmi
                    weightKg = profile.weightKg
                    heightCm = profile.heightCm
                    activityMinutes = profile.physicalActivityMinutes ?? 60
                }
            }
        }
    }

    private func refreshSnapshot() async {
        if let fetched = try? await dependencies.healthDataProvider.fetchWeeklySnapshot() {
            snapshot = fetched
        }
    }

    private func save() {
        guard let profile, let bmi else { return }
        profile.bmi = bmi
        profile.weightKg = weightKg
        profile.heightCm = heightCm
        profile.physicalActivityMinutes = activityMinutes
        try? modelContext.save()
        onSave()
        dismiss()
    }
}

#Preview {
    AssessHubView()
        .environment(\.appDependencies, .preview())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
