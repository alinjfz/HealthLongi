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
    @State private var healthKitLoadError: String?
    @State private var tooltipMetric: HealthKitMetric?
    @State private var showGenetics = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header

                    sectionHeader("Questionnaires")
                    ForEach(QuestionnaireKind.activeCases) { kind in
                        AssessmentCard(
                            title: kind.title,
                            subtitle: kind.subtitle,
                            icon: kind.icon,
                            isCompleted: completion(for: kind)
                        ) {
                            activeSheet = .questionnaire(kind)
                        }
                    }

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
                    if let healthKitLoadError {
                        Text(healthKitLoadError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4)
                    }
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
            .refreshable {
                await refreshHealthKit()
            }
            .onAppear {
                refreshViewModel()
                Task { await refreshHealthKit() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .demoHealthDataDidSeed)) { _ in
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
                case .labData(let userProfile):
                    LabDataInputView(profile: userProfile)
                case .calculators:
                    CalculatorsHubView(profile: profile, healthSnapshot: healthSnapshot)
                }
            }
            .sheet(item: $selectedHealthMetric) { metric in
                HealthKitDetailView(
                    metric: metric,
                    snapshot: healthSnapshot,
                    availability: metricAvailability(for: metric)
                )
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
            Text("Complete assessments at your own pace.")
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

    private func metricAvailability(for metric: HealthKitMetric) -> HealthKitMetricAvailability {
        HealthKitMetricAvailability.availability(
            for: metric,
            snapshot: healthSnapshot,
            isHealthDataAvailable: dependencies.healthDataProvider.isHealthDataAvailable
        )
    }

    private func healthKitCard(metric: HealthKitMetric) -> some View {
        let availability = metricAvailability(for: metric)
        let isEnabled = availability.isInteractive

        return HStack(spacing: 16) {
            Image(systemName: metric.icon)
                .font(.title2)
                .foregroundStyle(isEnabled ? NHSTheme.primaryBlue : NHSTheme.textSecondary)
                .frame(width: 44, height: 44)
                .background((isEnabled ? NHSTheme.primaryBlue : NHSTheme.textSecondary).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(metric.title)
                    .font(.headline)
                    .foregroundStyle(isEnabled ? NHSTheme.textPrimary : NHSTheme.textSecondary)
                Text(metric.subtitle)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

            Spacer()

            Text(metric.shortDisplay(from: healthSnapshot, availability: availability))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isEnabled ? NHSTheme.primaryBlue : NHSTheme.textSecondary)

            if isEnabled {
                Button {
                    selectedHealthMetric = metric
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NHSTheme.textSecondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    tooltipMetric = metric
                } label: {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { tooltipMetric == metric },
                    set: { if !$0 { tooltipMetric = nil } }
                )) {
                    Text(availability.tooltipMessage)
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: 280)
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .opacity(isEnabled ? 1 : 0.65)
        .nhsCard()
        .contentShape(Rectangle())
        .onTapGesture {
            if isEnabled {
                selectedHealthMetric = metric
            } else {
                tooltipMetric = metric
            }
        }
    }

    private func refreshViewModel() {
        viewModel = AssessmentHubViewModel(profile: profile)
    }

    private func refreshHealthKit() async {
        healthKitLoadError = nil
        guard dependencies.healthDataProvider.isHealthDataAvailable else {
            healthSnapshot = .empty
            healthKitLoadError = "HealthKit is not available on this device. Health metrics are disabled."
            return
        }
        do {
            try await dependencies.healthDataProvider.requestAuthorization()
            let snapshot = try await dependencies.healthDataProvider.fetchWeeklySnapshot()
            healthSnapshot = snapshot
            profile?.syncMetabolicData(from: snapshot)
            try? modelContext.save()
        } catch {
            healthSnapshot = .empty
            healthKitLoadError = error.localizedDescription
        }
    }
}

private enum AssessSheet: Identifiable {
    case questionnaire(QuestionnaireKind)
    case labData(UserProfile)
    case calculators

    var id: String {
        switch self {
        case .questionnaire(let kind): "q-\(kind.rawValue)"
        case .labData(let profile): "lab-\(profile.persistentModelID)"
        case .calculators: "calculators"
        }
    }
}

#Preview {
    AssessHubView()
        .environment(\.appDependencies, .preview())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
