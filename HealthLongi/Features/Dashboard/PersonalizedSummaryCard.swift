import SwiftUI

struct PersonalizedSummaryCard: View {
    let quote: MotivationalQuote
    let profile: AbstractedRiskProfile
    let summaryText: String?
    let usedFallback: Bool
    let isUpdating: Bool
    let lastUpdated: Date?
    let tips: [HealthTip]
    let completedTipIDs: Set<String>
    let onToggleTip: (String) -> Void

    @State private var isTipsExpanded = false
    @State private var isSummaryExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow

            riskBadges

            summaryContent

            if !tips.isEmpty {
                Button(isTipsExpanded ? "Show Less" : "Show Tips") {
                    withAnimation(.spring(duration: 0.35)) {
                        isTipsExpanded.toggle()
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NHSTheme.primaryBlue)

                if isTipsExpanded {
                    ForEach(tips) { tip in
                        GamifiedIcon(
                            tip: tip,
                            isCompleted: completedTipIDs.contains(tip.id),
                            onToggle: { onToggleTip(tip.id) }
                        )
                    }
                }
            }
        }
        .nhsCard()
        .onChange(of: summaryText) {
            isSummaryExpanded = false
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Health Summary")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.textPrimary)

                if isUpdating {
                    Text("Generating AI summary…")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.primaryBlue)
                } else if let lastUpdated {
                    Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }

            Spacer()

            if isUpdating {
                ProgressView()
                    .tint(NHSTheme.primaryBlue)
            }
        }
    }

    private var riskBadges: some View {
        HStack(spacing: 8) {
            riskBadge("Heart", color: NHSTheme.riskColor(for: profile.cardioRisk))
            riskBadge("Mind", color: NHSTheme.mentalColor(for: profile.mentalHealth))
            riskBadge("Metabolic", color: NHSTheme.riskColor(for: profile.metabolic))
        }
    }

    private func riskBadge(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(NHSTheme.lightBlue)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var summaryContent: some View {
        if isUpdating {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(NHSTheme.primaryBlue)
                    Text("Calculating scores and generating your summary…")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                if let summaryText, !summaryText.isEmpty {
                    Text("Showing your previous summary until the new one is ready.")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)

                    MarkdownSummaryText(
                        content: summaryText,
                        isExpanded: isSummaryExpanded
                    )
                    .opacity(0.55)
                }
            }
        } else if let summaryText, !summaryText.isEmpty {
            if usedFallback {
                Label("Offline summary — AI insights unavailable", systemImage: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            MarkdownSummaryText(
                content: summaryText,
                isExpanded: isSummaryExpanded
            )

            if MarkdownSummaryText.hasMoreContent(summaryText) {
                Button(isSummaryExpanded ? "Show Less" : "Full Summary") {
                    withAnimation(.spring(duration: 0.35)) {
                        isSummaryExpanded.toggle()
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NHSTheme.primaryBlue)
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: quote.category.icon)
                    .font(.title3)
                    .foregroundStyle(NHSTheme.primaryBlue)

                Text(quote.quote)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(NHSTheme.textPrimary)
            }
        }
    }
}
