import XCTest
@testable import HealthLongi

final class AIInsightTests: XCTestCase {
    func testResponseParserRejectsUnknownNhsTopicIds() {
        let json = """
        {
          "overallStatus": "watch",
          "gpDiscussionRecommended": false,
          "watchItems": [
            { "area": "mind", "finding": "GAD-7 score is 12", "nhsTopicId": "fake_topic", "severity": "moderate" },
            { "area": "mind", "finding": "GAD-7 score is 12", "nhsTopicId": "anxiety", "severity": "moderate" }
          ],
          "preventiveActions": [],
          "nhsReferences": [],
          "summaryMarkdown": "Your anxiety score suggests NHS self-help may help."
        }
        """

        let allowed: Set<String> = ["anxiety", "find_gp"]
        let raw = AIResponseParser.parse(content: json, allowedTopicIDs: allowed)
        XCTAssertEqual(raw?.watchItems?.count, 1)
        XCTAssertEqual(raw?.watchItems?.first?.nhsTopicId, "anxiety")
    }

    func testKnowledgeSelectorIncludesNhs111ForSevereDepression() {
        let context = sampleContext(
            phq9: 18,
            mental: .severeDepression
        )
        let ids = Set(NHSKnowledgeSelector.topics(for: context).map(\.id))
        XCTAssertTrue(ids.contains("nhs_111"))
        XCTAssertTrue(ids.contains("depression"))
    }

    func testInsightCodecRoundTrip() {
        let original = AISummaryResult(
            markdownSummary: "Test summary",
            suggestedLinkKeys: ["sleep", "find_gp"],
            usedFallback: false,
            watchItems: [AIWatchItem(area: "sleep", finding: "6.1h average", nhsTopicId: "sleep", severity: "low")],
            preventiveActions: [AIPreventiveAction(action: "Wind down earlier", rationale: "Below 7h", nhsTopicId: "sleep")],
            nhsReferences: [AINHSReference(topicId: "sleep", whyRelevant: "Short sleep")],
            overallStatus: .watch,
            gpDiscussionRecommended: false
        )

        let encoded = AIInsightCodec.encode(original)
        let decoded = AIInsightCodec.decode(from: encoded)
        XCTAssertEqual(decoded, original)
    }

    private func sampleContext(phq9: Int = 0, mental: MentalFlag = .none) -> AIHealthContext {
        AIHealthContext(
            demographics: AIDemographics(age: 40, sex: .female, smokingStatus: .never),
            healthKit: AIHealthKitMetrics(
                averageDailySteps: 5000,
                priorAverageDailySteps: 6000,
                averageRestingHeartRate: 72,
                averageSleepHours: 6.5,
                heartRateVariability: nil,
                oxygenSaturation: nil,
                activeEnergyKcalPerDay: nil,
                distanceKmPerDay: nil,
                weeklyExerciseMinutes: nil,
                mindfulMinutesPerDay: nil,
                bodyMassKg: 70,
                heightMetres: 1.7,
                bmi: 24.2,
                bodyFatPercent: nil,
                fetchedAt: .now
            ),
            trends: .empty,
            questionnaires: AIQuestionnaireScores(phq9: phq9, gad7: 0, who5: nil, pss10: nil, phq15: nil, auditC: nil),
            labs: nil,
            ruleProfile: AbstractedRiskProfile(
                cardioRisk: .low,
                mentalHealth: mental,
                metabolic: .low,
                correlations: [],
                labSignals: .empty
            ),
            ruleScores: AIRuleScores(cardioScore: 2, metabolicScore: 2, phq9Score: phq9, gad7Score: 0),
            priorAssessment: nil,
            nhsTopics: []
        )
    }
}
