import SwiftUI

struct MetabolicDetailContent: View {
    let riskLevel: RiskLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            riskSection
            recommendationsSection
            resourcesSection
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Level")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            HStack(spacing: 8) {
                Circle()
                    .fill(NHSTheme.riskColor(for: riskLevel))
                    .frame(width: 16, height: 16)
                Text(riskLevel.displayName)
                    .font(.subheadline.weight(.semibold))
            }

            Text(riskLevel.description)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommendations")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(recommendations, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resources")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(resourceLinks) { link in
                Link(destination: link.url) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(link.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(NHSTheme.primaryBlue)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(link.description)
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var recommendations: [String] {
        switch riskLevel {
        case .low:
            ["Maintain a balanced diet with plenty of vegetables",
             "Stay active with regular moderate exercise",
             "Monitor weight periodically"]
        case .moderate:
            ["Reduce sugary drinks and refined carbohydrates",
             "Aim for 150+ minutes of activity per week",
             "Ask your GP about diabetes screening"]
        case .high:
            ["Book a GP appointment for metabolic health review",
             "Consider structured weight management support",
             "Track waist circumference and blood sugar if advised"]
        }
    }

    private var resourceLinks: [NHSLink] {
        NHSLinks.links(forKeys: ["nhs_diabetes_prevention", "nhs_healthy_weight", "find_gp"])
    }
}
