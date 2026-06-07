import Foundation

enum AIInsightCodec {
    static func encode(_ result: AISummaryResult) -> String? {
        guard let data = try? JSONEncoder().encode(PersistedAIInsight(from: result)) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode(from json: String?) -> AISummaryResult? {
        guard let json,
              let data = json.data(using: .utf8),
              let persisted = try? JSONDecoder().decode(PersistedAIInsight.self, from: data) else {
            return nil
        }
        return persisted.toResult()
    }
}

private struct PersistedAIInsight: Codable {
    var markdownSummary: String
    var suggestedLinkKeys: [String]
    var usedFallback: Bool
    var watchItems: [AIWatchItem]
    var preventiveActions: [AIPreventiveAction]
    var nhsReferences: [AINHSReference]
    var overallStatus: String?
    var gpDiscussionRecommended: Bool

    init(from result: AISummaryResult) {
        markdownSummary = result.markdownSummary
        suggestedLinkKeys = result.suggestedLinkKeys
        usedFallback = result.usedFallback
        watchItems = result.watchItems
        preventiveActions = result.preventiveActions
        nhsReferences = result.nhsReferences
        overallStatus = result.overallStatus?.rawValue
        gpDiscussionRecommended = result.gpDiscussionRecommended
    }

    func toResult() -> AISummaryResult {
        AISummaryResult(
            markdownSummary: markdownSummary,
            suggestedLinkKeys: suggestedLinkKeys,
            usedFallback: usedFallback,
            watchItems: watchItems,
            preventiveActions: preventiveActions,
            nhsReferences: nhsReferences,
            overallStatus: overallStatus.flatMap { AIOverallStatus(rawString: $0) },
            gpDiscussionRecommended: gpDiscussionRecommended
        )
    }
}
