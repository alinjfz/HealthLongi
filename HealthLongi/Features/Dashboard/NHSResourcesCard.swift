import SwiftUI

struct NHSResourcesCard: View {
    let profile: AbstractedRiskProfile
    var suggestedLinkKeys: [String] = []

    private var links: [NHSLink] {
        let curated = NHSKnowledgeBase.links(forTopicIDs: suggestedLinkKeys)
        if !curated.isEmpty {
            return Array(curated.prefix(5))
        }
        return Array(NHSLinks.links(for: profile).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("NHS Resources", systemImage: "cross.case.fill")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if !suggestedLinkKeys.isEmpty {
                Text("Selected from NHS guidance cited in your summary.")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

            if links.isEmpty {
                Text("Complete an assessment to see personalised NHS resources.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                ForEach(links) { link in
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }
}
