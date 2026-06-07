import Foundation

struct AISummaryResult: Sendable, Equatable {
    var markdownSummary: String
    var suggestedLinkKeys: [String]
    var usedFallback: Bool
    var watchItems: [AIWatchItem]
    var preventiveActions: [AIPreventiveAction]
    var nhsReferences: [AINHSReference]
    var overallStatus: AIOverallStatus?
    var gpDiscussionRecommended: Bool

    static let fallback = AISummaryResult(
        markdownSummary: """
        Things look fairly steady overall. Keep up the small habits that work for you.

        Try one gentle step this week — a short walk, a consistent bedtime, or a moment to unwind.
        """,
        suggestedLinkKeys: ["nhs_111", "find_gp"],
        usedFallback: true,
        watchItems: [],
        preventiveActions: [],
        nhsReferences: [],
        overallStatus: nil,
        gpDiscussionRecommended: false
    )
}

struct AIWatchItem: Codable, Sendable, Equatable, Identifiable {
    var area: String
    var finding: String
    var nhsTopicId: String
    var severity: String

    var id: String { "\(area)-\(nhsTopicId)-\(finding)" }
}

struct AIPreventiveAction: Codable, Sendable, Equatable, Identifiable {
    var action: String
    var rationale: String
    var nhsTopicId: String

    var id: String { "\(nhsTopicId)-\(action)" }
}

struct AINHSReference: Codable, Sendable, Equatable, Identifiable {
    var topicId: String
    var whyRelevant: String

    var id: String { topicId }
}

enum AIOverallStatus: String, Codable, Sendable {
    case steady
    case watch
    case needsAttention = "needs_attention"

    init?(rawString: String) {
        switch rawString.lowercased() {
        case Self.steady.rawValue: self = .steady
        case Self.watch.rawValue: self = .watch
        case Self.needsAttention.rawValue, "needsattention": self = .needsAttention
        default: return nil
        }
    }
}

/// Raw structured payload from the model before validation.
struct AIRawInsightPayload: Codable {
    var overallStatus: String?
    var gpDiscussionRecommended: Bool?
    var watchItems: [AIWatchItem]?
    var preventiveActions: [AIPreventiveAction]?
    var nhsReferences: [AINHSReference]?
    var summaryMarkdown: String?
}
