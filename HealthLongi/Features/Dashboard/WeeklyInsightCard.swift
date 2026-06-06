import SwiftUI

struct WeeklyInsightCard: View {
    let insightText: String?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Weekly Insight", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let insightText {
                Text(insightText)
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Generated on your device. Not medical advice.")
                    .font(.caption2)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                Text("Complete assessments to receive a personalised weekly insight.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }
}

#Preview {
    WeeklyInsightCard(
        insightText: "Your sleep and activity patterns look steady this week.",
        isLoading: false
    )
    .padding()
}
