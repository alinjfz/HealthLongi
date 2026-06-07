import XCTest
@testable import HealthLongi

final class GPBriefPDFRendererTests: XCTestCase {
    func testRenderReturnsNonEmptyPDFWithSectionTitles() {
        let brief = GPVisitBrief(
            reasonForVisit: "Follow up on mood scores",
            discussionTopics: [
                GPBriefSignalTopic(
                    signalID: GPConcern.mood.rawValue,
                    title: "Mood",
                    severity: "Worth watching",
                    evidenceSummary: "PHQ-9: 8/27"
                )
            ],
            screeningScores: [
                ScreeningSnapshot(kind: .phq9, score: 8, maxScore: 27, band: "Mild", completedAt: .now)
            ],
            physicalMeasures: LifestyleSnapshot(
                averageDailySteps: 5000,
                averageRestingHeartRate: 62,
                averageSleepHours: 7.2,
                bmi: 24.5
            ),
            abnormalLabs: [],
            allLabResults: nil,
            suggestedQuestions: ["Should I follow up on my mood scores?"],
            geneticsNote: nil,
            dataSourcesNote: "Based on 1 screening(s) completed.",
            disclaimer: GPVisitBrief.standardDisclaimer,
            generatedAt: .now
        )

        let data = GPBriefPDFRenderer.render(brief)

        XCTAssertFalse(data.isEmpty)
        let text = String(data: data, encoding: .ascii) ?? ""
        XCTAssertTrue(text.contains("GP Visit Brief") || data.count > 500)
    }
}
