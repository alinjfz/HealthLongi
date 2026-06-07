import Foundation

enum AISummaryPrompts {
    static let systemPrompt = """
    You are a health insights assistant for the Vitals & Mind NHS-themed UK wellness app.

    CRITICAL RULES — follow exactly:
    1. Use ONLY the NHS KNOWLEDGE topics provided in the user message for any health advice, thresholds, or recommendations.
    2. Every watchItem, preventiveAction, and nhsReference MUST cite a valid nhsTopicId from the provided NHS KNOWLEDGE list.
    3. Do NOT invent medical facts, diagnoses, drug names, or URLs not in the NHS KNOWLEDGE list.
    4. Base findings on the USER HEALTH DATA provided — cite specific metrics (numbers allowed in JSON fields).
    5. Never diagnose. Use phrasing like "may benefit from", "worth discussing with your GP", "NHS suggests".
    6. If data is insufficient for a claim, omit it — do not guess.
    7. Respond with valid JSON only (no markdown fences, no commentary outside JSON).

    JSON schema:
    {
      "overallStatus": "steady" | "watch" | "needs_attention",
      "gpDiscussionRecommended": boolean,
      "watchItems": [
        { "area": "metabolic|heart|mind|activity|sleep|labs",
          "finding": "string referencing actual user metrics",
          "nhsTopicId": "must match NHS KNOWLEDGE id",
          "severity": "low|moderate|high" }
      ],
      "preventiveActions": [
        { "action": "specific actionable step",
          "rationale": "why, tied to user data",
          "nhsTopicId": "must match NHS KNOWLEDGE id" }
      ],
      "nhsReferences": [
        { "topicId": "must match NHS KNOWLEDGE id",
          "whyRelevant": "one sentence tied to user data" }
      ],
      "summaryMarkdown": "2 short paragraphs, plain English, under 120 words, gentle NHS tone. Mention that guidance is based on NHS information."
    }
    """

    static func userPrompt(for context: AIHealthContext) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let healthJSON = (try? String(data: encoder.encode(contextPayload(context)), encoding: .utf8)) ?? "{}"
        let nhsBlock = nhsKnowledgeBlock(context.nhsTopics)

        return """
        Analyse this person's health data and return JSON per the schema.

        === USER HEALTH DATA ===
        \(healthJSON)

        === NHS KNOWLEDGE (only source of truth for advice) ===
        \(nhsBlock)

        === ON-DEVICE RULE SUMMARY (for context, may inform findings) ===
        Cardio: \(context.ruleProfile.cardioRisk.displayName), Metabolic: \(context.ruleProfile.metabolic.displayName), \
        Mental: \(context.ruleProfile.mentalHealth.displayName), Correlations: \(context.ruleProfile.correlations.joined(separator: ", "))

        Return JSON only.
        """
    }

    private static func contextPayload(_ context: AIHealthContext) -> AIHealthContextPayload {
        AIHealthContextPayload(
            demographics: context.demographics,
            healthKit: context.healthKit,
            trends: context.trends,
            questionnaires: context.questionnaires,
            labs: context.labs,
            ruleScores: context.ruleScores,
            priorAssessment: context.priorAssessment,
            allowedNhsTopicIds: context.nhsTopics.map(\.id)
        )
    }

    private static func nhsKnowledgeBlock(_ topics: [NHSKnowledgeTopic]) -> String {
        topics.map { topic in
            """
            [\(topic.id)] \(topic.title)
            URL: \(topic.url.absoluteString)
            \(topic.excerpt)
            \(topic.thresholds.map { "Thresholds: \($0)" } ?? "")
            """
        }.joined(separator: "\n\n")
    }
}

private struct AIHealthContextPayload: Codable {
    var demographics: AIDemographics
    var healthKit: AIHealthKitMetrics
    var trends: TrendDigest
    var questionnaires: AIQuestionnaireScores
    var labs: LabResults?
    var ruleScores: AIRuleScores
    var priorAssessment: AIPriorAssessment?
    var allowedNhsTopicIds: [String]
}
