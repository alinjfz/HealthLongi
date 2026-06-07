import Foundation

enum AIResponseParser {
    static func parse(content: String, allowedTopicIDs: Set<String>) -> AIRawInsightPayload? {
        let trimmed = stripCodeFences(content)
        guard let data = trimmed.data(using: .utf8),
              let raw = try? JSONDecoder().decode(AIRawInsightPayload.self, from: data) else {
            return nil
        }
        return sanitize(raw, allowedTopicIDs: allowedTopicIDs)
    }

    static func makeResult(
        from raw: AIRawInsightPayload?,
        context: AIHealthContext,
        usedFallback: Bool
    ) -> AISummaryResult {
        guard let raw, let summary = raw.summaryMarkdown, !summary.isEmpty else {
            return NHSGroundedFallback.make(context: context)
        }

        let topicIDs = Set(context.nhsTopics.map(\.id))
        let watchItems = (raw.watchItems ?? []).filter { topicIDs.contains($0.nhsTopicId) }
        let actions = (raw.preventiveActions ?? []).filter { topicIDs.contains($0.nhsTopicId) }
        let references = (raw.nhsReferences ?? []).filter { topicIDs.contains($0.topicId) }

        let refIDs = Set(references.map(\.topicId) + watchItems.map(\.nhsTopicId) + actions.map(\.nhsTopicId))
        var linkKeys = Array(refIDs)
        if linkKeys.isEmpty {
            linkKeys = NHSKnowledgeSelector.topics(for: context).map(\.id)
        }

        return AISummaryResult(
            markdownSummary: summary,
            suggestedLinkKeys: linkKeys,
            usedFallback: usedFallback,
            watchItems: watchItems,
            preventiveActions: actions,
            nhsReferences: references,
            overallStatus: raw.overallStatus.flatMap { AIOverallStatus(rawString: $0) } ?? inferredStatus(context),
            gpDiscussionRecommended: raw.gpDiscussionRecommended ?? (context.ruleProfile.mentalHealth == .severeDepression || context.ruleProfile.mentalHealth == .highAnxiety)
        )
    }

    private static func sanitize(_ raw: AIRawInsightPayload, allowedTopicIDs: Set<String>) -> AIRawInsightPayload {
        var copy = raw
        copy.watchItems = raw.watchItems?.filter { allowedTopicIDs.contains($0.nhsTopicId) }
        copy.preventiveActions = raw.preventiveActions?.filter { allowedTopicIDs.contains($0.nhsTopicId) }
        copy.nhsReferences = raw.nhsReferences?.filter { allowedTopicIDs.contains($0.topicId) }
        return copy
    }

    private static func inferredStatus(_ context: AIHealthContext) -> AIOverallStatus {
        let p = context.ruleProfile
        if p.cardioRisk == .high || p.metabolic == .high || p.mentalHealth == .severeDepression || p.mentalHealth == .highAnxiety {
            return .needsAttention
        }
        if p.cardioRisk == .moderate || p.metabolic == .moderate || !p.correlations.isEmpty {
            return .watch
        }
        return .steady
    }

    private static func stripCodeFences(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            s = s.replacingOccurrences(of: "```json", with: "")
            s = s.replacingOccurrences(of: "```", with: "")
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = s.firstIndex(of: "{"), let end = s.lastIndex(of: "}") {
            s = String(s[start...end])
        }
        return s
    }
}
