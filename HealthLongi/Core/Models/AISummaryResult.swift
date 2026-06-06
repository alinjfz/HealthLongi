import Foundation

struct AISummaryResult: Sendable, Equatable {
    var markdownSummary: String
    var suggestedLinkKeys: [String]
    var usedFallback: Bool

    static let fallback = AISummaryResult(
        markdownSummary: """
        ## Your health summary

        Based on your assessment scores, we recommend speaking with your GP for personalised advice.

        **Next steps:**
        - Book an appointment with your GP
        - Visit [NHS 111 online](https://111.nhs.uk/) if you need guidance now
        """,
        suggestedLinkKeys: ["nhs_111", "find_gp"],
        usedFallback: true
    )
}
