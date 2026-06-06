import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \RiskAssessment.timestamp, order: .reverse) private var assessments: [RiskAssessment]
    @Query private var profiles: [UserProfile]

    @State private var viewModel: DashboardViewModel
    @State private var selectedDomain: HealthDomain?
    @State private var activeQuestionnaire: QuestionnaireKind?
    @State private var selectedSignal: HealthSignal?

    init() {
        _viewModel = State(initialValue: DashboardViewModel())
    }

    private var profile: AbstractedRiskProfile {
        viewModel.latestAssessment?.abstractedProfile ?? .placeholder
    }

    private var summaryText: String? {
        viewModel.latestSummary?.markdownSummary ?? viewModel.latestAssessment?.aiSummaryText
    }

    var body: some View {
        NavigationStack {
            dashboardContent
                .background(NHSTheme.background)
                .navigationTitle("Dashboard")
                .onAppear {
                    viewModel = DashboardViewModel(healthDataProvider: dependencies.healthDataProvider)
                    viewModel.loadLatest(from: assessments)
                    viewModel.refreshSignals(profile: profiles.first)
                    Task { await refreshAndAssess(reason: .appOpened) }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await refreshAndAssess(reason: .appOpened) }
                }
                .onChange(of: assessments.count) {
                    guard !viewModel.isUpdatingAssessment else { return }
                    viewModel.loadLatest(from: assessments, preferExistingSummary: true)
                }
                .onChange(of: profiles.first?.phq9Score) {
                    viewModel.markQuestionnaireDataUpdated()
                    viewModel.refreshSignals(profile: profiles.first)
                    Task { await runAssessmentIfNeeded(reason: .newData) }
                }
                .onChange(of: profiles.first?.gad7Score) {
                    viewModel.markQuestionnaireDataUpdated()
                    viewModel.refreshSignals(profile: profiles.first)
                    Task { await runAssessmentIfNeeded(reason: .newData) }
                }
                .sheet(item: $selectedSignal) { signal in
                    HealthSignalDetailSheet(signal: signal)
                }
                .sheet(item: $selectedDomain) { domain in
                    DomainDetailView(domain: domain, profile: profile)
                }
                .sheet(item: $activeQuestionnaire) { kind in
                    if let userProfile = profiles.first {
                        QuestionnaireSheetView(kind: kind, profile: userProfile, modelContext: modelContext) {
                            viewModel.markQuestionnaireDataUpdated()
                            Task { await runAssessmentIfNeeded(reason: .newData) }
                        }
                    }
                }
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                overviewContent
            }
            .padding()
        }
        .refreshable {
            await runAssessmentIfNeeded(reason: .userRefresh)
        }
    }

    private var overviewContent: some View {
        Group {
            PersonalizedSummaryCard(
                quote: viewModel.motivationalQuote,
                profile: profile,
                summaryText: summaryText,
                usedFallback: viewModel.latestSummary?.usedFallback ?? viewModel.latestAssessment?.usedAIFallback ?? false,
                isUpdating: viewModel.isUpdatingAssessment,
                lastUpdated: viewModel.latestAssessment?.timestamp,
                tips: viewModel.selectedTips,
                completedTipIDs: viewModel.completedTipIDs,
                onToggleTip: { viewModel.toggleTipCompletion($0) }
            )

            HealthSignalsCard(signals: viewModel.healthSignals) { signal in
                selectedSignal = signal
            }

            BodyMapView(
                profile: profile,
                snapshot: viewModel.healthSnapshot ?? .empty,
                onSelectQuestionnaire: { activeQuestionnaire = $0 }
            )

            if let lastRefreshed = viewModel.lastRefreshedAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Health data synced \(lastRefreshed.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                }
                .foregroundStyle(NHSTheme.textSecondary)
            }

            TrendsContentView()

            DomainStatusCard(
                title: "Cardiovascular",
                subtitle: "Heart & circulation risk",
                color: NHSTheme.riskColor(for: profile.cardioRisk),
                icon: "heart.fill",
                action: { selectedDomain = .cardiovascular }
            )

            DomainStatusCard(
                title: "Mental Health",
                subtitle: "Mood & anxiety indicators",
                color: NHSTheme.mentalColor(for: profile.mentalHealth),
                icon: "brain.head.profile",
                action: { selectedDomain = .mental }
            )

            DomainStatusCard(
                title: "Metabolic",
                subtitle: "Diabetes & weight risk",
                color: NHSTheme.riskColor(for: profile.metabolic),
                icon: "figure.walk",
                action: { selectedDomain = .metabolic }
            )

            if !profile.correlations.isEmpty {
                correlationsCard
            }

            NHSResourcesCard(profile: profile)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .nhsCard()
            }
        }
    }

    private func refreshAndAssess(reason: AutoAssessmentReason) async {
        guard let profile = profiles.first, profile.phq9Score > 0 || profile.gad7Score > 0 else { return }

        viewModel.isUpdatingAssessment = true
        defer { viewModel.isUpdatingAssessment = false }

        await viewModel.refreshHealthKit()
        if let profile = profiles.first, let snapshot = viewModel.healthSnapshot {
            profile.syncMetabolicData(from: snapshot)
            try? modelContext.save()
        }
        viewModel.refreshSignals(profile: profiles.first)
        try? modelContext.save()
        await viewModel.autoRunAssessmentIfNeeded(
            profile: profile,
            orchestrator: dependencies.orchestrator,
            modelContext: modelContext,
            reason: reason,
            showsProgress: false
        )
    }

    private func runAssessmentIfNeeded(reason: AutoAssessmentReason) async {
        await viewModel.refreshHealthKit()
        if let profile = profiles.first, let snapshot = viewModel.healthSnapshot {
            profile.syncMetabolicData(from: snapshot)
            try? modelContext.save()
        }
        viewModel.refreshSignals(profile: profiles.first)
        try? modelContext.save()
        await viewModel.autoRunAssessmentIfNeeded(
            profile: profiles.first,
            orchestrator: dependencies.orchestrator,
            modelContext: modelContext,
            reason: reason
        )
    }

    private var correlationsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Mind-Body Connections", systemImage: "link")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(profile.correlations, id: \.self) { correlation in
                Text(correlationLabel(correlation))
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private func correlationLabel(_ key: String) -> String {
        switch key {
        case "dropping_steps_with_high_gad7":
            "Decreased activity alongside elevated anxiety"
        case "poor_sleep_with_high_anxiety":
            "Poor sleep alongside elevated anxiety"
        case "poor_sleep_with_elevated_depression":
            "Poor sleep alongside elevated depression"
        case "low_activity_with_elevated_depression":
            "Low activity alongside elevated depression"
        default:
            key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.appDependencies, .preview())
        .modelContainer(for: [UserProfile.self, RiskAssessment.self], inMemory: true)
}
