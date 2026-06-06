import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RiskAssessment.timestamp, order: .reverse) private var assessments: [RiskAssessment]
    @Query private var profiles: [UserProfile]

    @State private var viewModel = DashboardViewModel()
    @State private var showResults = false

    private var profile: AbstractedRiskProfile {
        viewModel.latestAssessment?.abstractedProfile ?? .placeholder
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
                viewModel.loadLatest(from: assessments)
            }
            .onChange(of: assessments.count) {
                viewModel.loadLatest(from: assessments)
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
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                DomainStatusCard(
                    title: "Cardiovascular",
                    subtitle: "Heart & circulation risk",
                    status: profile.cardioRisk.displayName,
                    color: NHSTheme.riskColor(for: profile.cardioRisk),
                    icon: "heart.fill"
                )

                DomainStatusCard(
                    title: "Mental Health",
                    subtitle: "Mood & anxiety indicators",
                    status: profile.mentalHealth.displayName,
                    color: NHSTheme.mentalColor(for: profile.mentalHealth),
                    icon: "brain.head.profile"
                )

                DomainStatusCard(
                    title: "Metabolic",
                    subtitle: "Diabetes & weight risk",
                    status: profile.metabolic.displayName,
                    color: NHSTheme.riskColor(for: profile.metabolic),
                    icon: "figure.walk"
                )

                if !profile.correlations.isEmpty {
                    correlationsCard
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .nhsCard()
                }

                Button("Run Assessment") {
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
                .buttonStyle(NHSPrimaryButtonStyle())

                if viewModel.latestAssessment != nil {
                    Button("View Latest Results") {
                        showResults = true
                    }
                    .buttonStyle(.bordered)
                    .tint(NHSTheme.primaryBlue)
                }
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Health Overview")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)
            Text("Scores are calculated on-device. Only abstracted categories are sent for AI summary.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
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
