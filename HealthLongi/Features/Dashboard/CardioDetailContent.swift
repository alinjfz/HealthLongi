import SwiftUI

struct CardioDetailContent: View {
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
                Link(link.title, destination: link.url)
                    .font(.subheadline)
            }
        }
        .nhsCard()
    }

    private var recommendations: [String] {
        switch riskLevel {
        case .low:
            ["Stay active with at least 150 minutes of moderate activity per week",
             "Maintain a balanced diet low in saturated fat",
             "Monitor blood pressure periodically"]
        case .moderate:
            ["Increase daily walking — aim for 7,000+ steps",
             "Reduce salt intake and processed foods",
             "Discuss cholesterol screening with your GP"]
        case .high:
            ["Book a GP appointment for cardiovascular review",
             "Start with gentle daily activity and build gradually",
             "Track resting heart rate and report significant changes"]
        }
    }

    private var resourceLinks: [NHSLink] {
        NHSLinks.links(forKeys: ["nhs_heart_health", "nhs_active_10", "find_gp"])
    }
}
