import Foundation

struct AISummaryResult: Sendable, Equatable {
    var markdownSummary: String
    var suggestedLinkKeys: [String]
    var usedFallback: Bool

    static let fallback = AISummaryResult(
        markdownSummary: """
        Things look fairly steady overall. Keep up the small habits that work for you.

        Try one gentle step this week — a short walk, a consistent bedtime, or a moment to unwind.
        """,
        suggestedLinkKeys: ["nhs_111", "find_gp"],
        usedFallback: true
    )
}
