import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ResultsView: View {
    let assessment: RiskAssessment
    let summary: AISummaryResult

    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?

    private var nhsLinks: [NHSLink] {
        NHSLinks.links(forKeys: summary.suggestedLinkKeys)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if summary.usedFallback {
                        Label("Offline summary — connect for AI insights", systemImage: "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .nhsCard()
                    }

                    domainSummary

                    markdownSection

                    nhsLinksSection
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Your Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    private var domainSummary: some View {
        let profile = assessment.abstractedProfile
        return VStack(spacing: 12) {
            DomainStatusCard(
                title: "Cardiovascular",
                subtitle: "On-device score",
                status: profile.cardioRisk.displayName,
                color: NHSTheme.riskColor(for: profile.cardioRisk),
                icon: "heart.fill"
            )
            DomainStatusCard(
                title: "Mental Health",
                subtitle: "On-device score",
                status: profile.mentalHealth.displayName,
                color: NHSTheme.mentalColor(for: profile.mentalHealth),
                icon: "brain.head.profile"
            )
            DomainStatusCard(
                title: "Metabolic",
                subtitle: "On-device score",
                status: profile.metabolic.displayName,
                color: NHSTheme.riskColor(for: profile.metabolic),
                icon: "figure.walk"
            )
        }
    }

    private var markdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personalised Summary")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if let attributed = try? AttributedString(
                markdown: summary.markdownSummary,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attributed)
                    .foregroundStyle(NHSTheme.textPrimary)
            } else {
                Text(summary.markdownSummary)
                    .foregroundStyle(NHSTheme.textPrimary)
            }
        }
        .nhsCard()
    }

    private var nhsLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NHS Resources")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(nhsLinks) { link in
                Button {
                    selectedURL = link.url
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(link.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(NHSTheme.primaryBlue)
                        Text(link.description)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(NHSTheme.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    ResultsView(
        assessment: RiskAssessment(
            profile: AbstractedRiskProfile(
                cardioRisk: .moderate,
                mentalHealth: .highAnxiety,
                metabolic: .low,
                correlations: ["dropping_steps_with_high_gad7"]
            ),
            aiSummaryText: "## Summary\nYour assessment suggests elevated anxiety alongside reduced activity.",
            phq9Score: 8,
            gad7Score: 14,
            metabolicScore: 4,
            cardioScore: 6
        ),
        summary: AISummaryResult(
            markdownSummary: "## Summary\nYour assessment suggests elevated anxiety alongside reduced activity.",
            suggestedLinkKeys: ["nhs_talking_therapies"],
            usedFallback: true
        )
    )
}
