import Foundation

/// Offline fallback that only uses curated NHS topics — no invented advice.
enum NHSGroundedFallback {
    static func make(context: AIHealthContext) -> AISummaryResult {
        let topics = context.nhsTopics
        let profile = context.ruleProfile
        var references: [AINHSReference] = []
        var watchItems: [AIWatchItem] = []
        var actions: [AIPreventiveAction] = []

        if profile.labSignals.elevatedGlucose, let topic = NHSKnowledgeBase.topic(id: "nhs_diabetes_prevention") {
            watchItems.append(AIWatchItem(
                area: "metabolic",
                finding: "Blood sugar markers are elevated in your saved lab results.",
                nhsTopicId: topic.id,
                severity: "moderate"
            ))
            references.append(AINHSReference(topicId: topic.id, whyRelevant: "Lab glucose markers need lifestyle review per NHS guidance."))
            actions.append(AIPreventiveAction(
                action: "Add a 15-minute daily walk and review diet with NHS healthy weight guidance.",
                rationale: "NHS states activity and weight management reduce type 2 diabetes risk.",
                nhsTopicId: topic.id
            ))
        }

        if profile.labSignals.elevatedBloodPressure, let topic = NHSKnowledgeBase.topic(id: "high_blood_pressure") {
            watchItems.append(AIWatchItem(
                area: "heart",
                finding: "Blood pressure readings in your labs are above typical NHS targets.",
                nhsTopicId: topic.id,
                severity: "moderate"
            ))
            references.append(AINHSReference(topicId: topic.id, whyRelevant: "NHS recommends GP review for raised blood pressure."))
        }

        if profile.mentalHealth == .moderateAnxiety || profile.mentalHealth == .highAnxiety,
           let topic = NHSKnowledgeBase.topic(id: "nhs_talking_therapies") {
            watchItems.append(AIWatchItem(
                area: "mind",
                finding: "Anxiety screening scores suggest symptoms worth addressing.",
                nhsTopicId: topic.id,
                severity: profile.mentalHealth == .highAnxiety ? "high" : "moderate"
            ))
            references.append(AINHSReference(topicId: topic.id, whyRelevant: "NHS talking therapies are free and can be self-referred."))
        }

        if context.healthKit.averageDailySteps < 5000, let topic = NHSKnowledgeBase.topic(id: "physical_activity") {
            actions.append(AIPreventiveAction(
                action: "Build toward 150 minutes of moderate activity per week, starting with short daily walks.",
                rationale: "Your step count is below active levels; NHS recommends regular movement.",
                nhsTopicId: topic.id
            ))
            references.append(AINHSReference(topicId: topic.id, whyRelevant: "Low activity compared to NHS weekly targets."))
        }

        if references.isEmpty, let gp = NHSKnowledgeBase.topic(id: "find_gp") {
            references.append(AINHSReference(topicId: gp.id, whyRelevant: "General NHS guidance for discussing results with your GP."))
        }

        let markdown = GLMPrompts.fallbackText(for: profile)
            + "\n\n_Guidance based on NHS information. AI summary was unavailable._"

        let status: AIOverallStatus
        if profile.cardioRisk == .high || profile.metabolic == .high
            || profile.mentalHealth == .severeDepression || profile.mentalHealth == .highAnxiety {
            status = .needsAttention
        } else if profile.cardioRisk == .moderate || profile.metabolic == .moderate || !profile.correlations.isEmpty {
            status = .watch
        } else {
            status = .steady
        }

        return AISummaryResult(
            markdownSummary: markdown,
            suggestedLinkKeys: references.map(\.topicId),
            usedFallback: true,
            watchItems: watchItems,
            preventiveActions: actions,
            nhsReferences: references,
            overallStatus: status,
            gpDiscussionRecommended: profile.mentalHealth == .severeDepression || profile.mentalHealth == .highAnxiety
        )
    }
}
