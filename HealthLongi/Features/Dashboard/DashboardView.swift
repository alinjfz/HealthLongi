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
    @State private var showSummaryInfo = false

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
                    Task { await refreshAndAssess(reason: .appOpened) }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await refreshAndAssess(reason: .appOpened) }
                }
                .onReceive(NotificationCenter.default.publisher(for: .demoHealthDataDidSeed)) { _ in
                    Task { await refreshAndAssess(reason: .newData) }
                }
                .onReceive(NotificationCenter.default.publisher(for: .labDataDidUpdate)) { _ in
                    viewModel.markLabDataUpdated()
                    Task { await runAssessmentIfNeeded(reason: .newData) }
                }
                .onReceive(NotificationCenter.default.publisher(for: .questionnaireDataDidUpdate)) { _ in
                    viewModel.markQuestionnaireDataUpdated()
                    Task { await runAssessmentIfNeeded(reason: .newData) }
                }
                .onChange(of: assessments.count) {
                    guard !viewModel.isUpdatingAssessment else { return }
                    viewModel.loadLatest(from: assessments, preferExistingSummary: true)
                }
                .onChange(of: profiles.first?.phq9Score) {
                    viewModel.markQuestionnaireDataUpdated()
                    Task { await runAssessmentIfNeeded(reason: .newData) }
                }
                .onChange(of: profiles.first?.gad7Score) {
                    viewModel.markQuestionnaireDataUpdated()
                    Task { await runAssessmentIfNeeded(reason: .newData) }
                }
                .sheet(item: $selectedDomain) { domain in
                    DomainDetailView(domain: domain, profile: profile)
                }
                .sheet(isPresented: $showSummaryInfo) {
                    HealthSummaryInfoSheet(
                        assessment: viewModel.latestAssessment,
                        userProfile: profiles.first,
                        healthSnapshot: viewModel.healthSnapshot,
                        summaryResult: viewModel.latestSummary
                    )
                }
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BodyMapView(
                    profile: profile,
                    snapshot: viewModel.healthSnapshot ?? .empty,
                    labResults: profiles.first?.labResults,
                    userProfile: profiles.first
                )

                PersonalizedSummaryCard(
                    quote: viewModel.motivationalQuote,
                    profile: profile,
                    summaryText: summaryText,
                    usedFallback: viewModel.latestSummary?.usedFallback ?? viewModel.latestAssessment?.usedAIFallback ?? false,
                    isUpdating: viewModel.isUpdatingAssessment,
                    lastUpdated: viewModel.latestAssessment?.timestamp,
                    tips: viewModel.selectedTips,
                    completedTipIDs: viewModel.completedTipIDs,
                    correlations: profile.correlations,
                    watchItems: viewModel.latestSummary?.watchItems ?? [],
                    preventiveActions: viewModel.latestSummary?.preventiveActions ?? [],
                    onToggleTip: { viewModel.toggleTipCompletion($0) },
                    onShowInfo: { showSummaryInfo = true }
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

                DomainStatusCard(
                    title: "Metabolic",
                    subtitle: "Diabetes & weight risk",
                    color: NHSTheme.riskColor(for: profile.metabolic),
                    icon: "figure.walk",
                    action: { selectedDomain = .metabolic }
                )

                DomainStatusCard(
                    title: "Mental Health",
                    subtitle: "Mood & anxiety indicators",
                    color: NHSTheme.mentalColor(for: profile.mentalHealth),
                    icon: "brain.head.profile",
                    action: { selectedDomain = .mental }
                )

                DomainStatusCard(
                    title: "Cardiovascular",
                    subtitle: "Heart & circulation risk",
                    color: NHSTheme.riskColor(for: profile.cardioRisk),
                    icon: "heart.fill",
                    action: { selectedDomain = .cardiovascular }
                )

                TrendsCard()

                NHSResourcesCard(
                    profile: profile,
                    suggestedLinkKeys: viewModel.latestSummary?.suggestedLinkKeys ?? []
                )

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .nhsCard()
                }
            }
            .padding()
        }
        .refreshable {
            await runAssessmentIfNeeded(reason: .userRefresh)
        }
    }

    private func refreshAndAssess(reason: AutoAssessmentReason) async {
        guard let profile = profiles.first, profile.phq9Score > 0 || profile.gad7Score > 0 else { return }

        viewModel.isUpdatingAssessment = true
        defer { viewModel.isUpdatingAssessment = false }

        await viewModel.refreshHealthKit()
        if let snapshot = viewModel.healthSnapshot {
            profile.syncMetabolicData(from: snapshot)
            try? modelContext.save()
        }
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
        await viewModel.autoRunAssessmentIfNeeded(
            profile: profiles.first,
            orchestrator: dependencies.orchestrator,
            modelContext: modelContext,
            reason: reason
        )
    }

}

#Preview {
    DashboardView()
        .environment(\.appDependencies, .preview())
        .modelContainer(for: [UserProfile.self, RiskAssessment.self], inMemory: true)
}
