import SwiftUI

struct MentalDetailContent: View {
    let mentalFlag: MentalFlag

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            riskSection
            recommendationsSection
            resourcesSection
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            HStack(spacing: 8) {
                Circle()
                    .fill(NHSTheme.mentalColor(for: mentalFlag))
                    .frame(width: 16, height: 16)
                Text(mentalFlag.displayName)
                    .font(.subheadline.weight(.semibold))
            }

            Text(mentalDescription)
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
                            Text(link.description)
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                                .lineLimit(2)
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

    private var mentalDescription: String {
        switch mentalFlag {
        case .none:
            "No significant mental health concerns detected from your screening responses."
        case .mild:
            "Mild symptoms detected. Self-care strategies and monitoring may be helpful."
        case .moderateDepression, .moderateAnxiety:
            "Moderate symptoms detected. Professional support through NHS Talking Therapies may help."
        case .severeDepression, .highAnxiety:
            "Significant symptoms detected. Please consider reaching out to your GP or NHS 111."
        }
    }

    private var recommendations: [String] {
        switch mentalFlag {
        case .none, .mild:
            ["Practice regular mindfulness or breathing exercises",
             "Maintain social connections and daily routines",
             "Prioritise sleep and physical activity"]
        case .moderateDepression, .moderateAnxiety:
            ["Self-refer to NHS Talking Therapies",
             "Talk to someone you trust about how you feel",
             "Keep a mood diary to track patterns"]
        case .severeDepression, .highAnxiety:
            ["Contact your GP as soon as possible",
             "If in crisis, call NHS 111 or Samaritans on 116 123",
             "Do not wait — professional help is available"]
        }
    }

    private var resourceLinks: [NHSLink] {
        NHSLinks.links(forKeys: ["nhs_talking_therapies", "nhs_mental_health", "nhs_111"])
    }
}
