import SwiftUI

struct PersonalizedSummaryCard: View {
    let quote: MotivationalQuote
    let summaryText: String?
    let tips: [HealthTip]
    let completedTipIDs: Set<String>
    let onToggleTip: (String) -> Void

    @State private var isExpanded = false

    private var previewText: String {
        if let summaryText, !summaryText.isEmpty {
            return String(summaryText.prefix(120)) + (summaryText.count > 120 ? "…" : "")
        }
        return quote.quote
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: quote.category.icon)
                    .font(.title3)
                    .foregroundStyle(NHSTheme.primaryBlue)

                VStack(alignment: .leading, spacing: 6) {
                    Text(quote.quote)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NHSTheme.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)

                    if isExpanded {
                        if let summaryText, !summaryText.isEmpty {
                            Divider()
                            Text(summaryText)
                                .font(.subheadline)
                                .foregroundStyle(NHSTheme.textSecondary)
                        }

                        if !tips.isEmpty {
                            Divider()
                            Text("Today's Tips")
                                .font(.headline)
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
            }

            Button(isExpanded ? "Show Less" : "Show More") {
                withAnimation(.spring(duration: 0.35)) {
                    isExpanded.toggle()
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(NHSTheme.primaryBlue)
        }
        .nhsCard()
    }
}
