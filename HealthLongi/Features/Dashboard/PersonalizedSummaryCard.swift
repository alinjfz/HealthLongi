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
    let correlations: [String]
    let watchItems: [AIWatchItem]
    let preventiveActions: [AIPreventiveAction]
    let onToggleTip: (String) -> Void
    let onShowInfo: () -> Void

    @State private var isDetailsExpanded = false

    private var hasExpandableDetails: Bool {
        !correlations.isEmpty
            || !watchItems.isEmpty
            || !preventiveActions.isEmpty
            || !tips.isEmpty
            || (summaryText.map { MarkdownSummaryText.hasMoreContent($0) } ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            riskBadges
            summaryContent

            if isDetailsExpanded {
                detailsContent
            }

            if hasExpandableDetails && !isUpdating {
                Button(isDetailsExpanded ? "Show Less" : "Show More") {
                    withAnimation(.spring(duration: 0.35)) {
                        isDetailsExpanded.toggle()
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NHSTheme.primaryBlue)
            }
        }
        .nhsCard()
        .onChange(of: summaryText) {
            isDetailsExpanded = false
        }
    }

    @ViewBuilder
    private var detailsContent: some View {
        if !correlations.isEmpty {
            correlationsRow
        }

        if !watchItems.isEmpty {
            watchListSection
        }

        if !preventiveActions.isEmpty {
            preventiveActionsSection
        }

        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tips for you")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NHSTheme.primaryBlue)

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
            } else {
                Button(action: onShowInfo) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(NHSTheme.primaryBlue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About this health summary")
            }
        }
    }

    private var watchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watch this week")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(watchItems) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.finding)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textPrimary)
                    if let topic = NHSKnowledgeBase.topic(id: item.nhsTopicId) {
                        Link(destination: topic.url) {
                            Label(topic.title, systemImage: "link")
                                .font(.caption)
                                .foregroundStyle(NHSTheme.primaryBlue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(NHSTheme.lightBlue.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var preventiveActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NHS-aligned steps")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(preventiveActions) { action in
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.action)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text(action.rationale)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                    if let topic = NHSKnowledgeBase.topic(id: action.nhsTopicId) {
                        Link(destination: topic.url) {
                            Label("NHS: \(topic.title)", systemImage: "arrow.up.right")
                                .font(.caption2)
                                .foregroundStyle(NHSTheme.primaryBlue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(NHSTheme.lightBlue.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var correlationsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Patterns detected")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(correlations, id: \.self) { key in
                Label(CorrelationLabels.displayName(for: key), systemImage: "link")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(NHSTheme.lightBlue.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                        isExpanded: false
                    )
                    .opacity(0.55)
                }
            }
        } else if let summaryText, !summaryText.isEmpty {
            if usedFallback && isDetailsExpanded {
                Label("Offline summary — AI insights unavailable", systemImage: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            MarkdownSummaryText(
                content: summaryText,
                isExpanded: isDetailsExpanded
            )
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
