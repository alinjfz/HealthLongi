import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RiskAssessment.timestamp, order: .reverse) private var assessments: [RiskAssessment]
    @Query private var profiles: [UserProfile]

    @State private var viewModel: DashboardViewModel
    @State private var showResults = false
    @State private var selectedDomain: HealthDomain?

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
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Calculating scores and generating your summary…")
                } else {
                    dashboardContent
                }
            }
            .background(NHSTheme.background)
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel = DashboardViewModel(healthDataProvider: dependencies.healthDataProvider)
                viewModel.loadLatest(from: assessments)
                Task { await viewModel.refreshHealthKit() }
            }
            .onChange(of: assessments.count) {
                viewModel.loadLatest(from: assessments)
            }
            .onChange(of: profiles.first?.phq9Score) {
                viewModel.markQuestionnaireDataUpdated()
            }
            .onChange(of: profiles.first?.gad7Score) {
                viewModel.markQuestionnaireDataUpdated()
            }
            .sheet(isPresented: $showResults) {
                if let assessment = viewModel.latestAssessment {
                    ResultsView(
                        assessment: assessment,
                        summary: viewModel.latestSummary ?? AISummaryResult(
                            markdownSummary: assessment.aiSummaryText,
                            suggestedLinkKeys: NHSLinks.links(for: assessment.abstractedProfile).map(\.id),
                            usedFallback: assessment.usedAIFallback
                        )
                    )
                }
            }
            .sheet(item: $selectedDomain) { domain in
                DomainDetailView(domain: domain, profile: profile)
            }
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Personalized summary always at the top
                PersonalizedSummaryCard(
                    quote: viewModel.motivationalQuote,
                    summaryText: summaryText,
                    tips: viewModel.selectedTips,
                    completedTipIDs: viewModel.completedTipIDs,
                    onToggleTip: { viewModel.toggleTipCompletion($0) }
                )

                // Last refreshed indicator
                if let lastRefreshed = viewModel.lastRefreshedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Health data synced \(lastRefreshed.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                    }
                    .foregroundStyle(NHSTheme.textSecondary)
                }

                // Domain status cards
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

                // Gamified Assessment CTA
                let readiness = viewModel.readinessProgress(for: profiles.first)
                AssessmentCTACard(
                    profile: profiles.first,
                    readiness: readiness,
                    hasNewData: viewModel.hasNewHealthData || viewModel.hasNewQuestionnaireData,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.runAssessment(
                            profile: profiles.first,
                            orchestrator: dependencies.orchestrator,
                            modelContext: modelContext
                        )
                        if viewModel.latestAssessment != nil {
                            showResults = true
                        }
                    }
                }

                NHSResourcesCard(profile: profile)

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
            await viewModel.refreshHealthKit()
        }
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
            }
        }
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
