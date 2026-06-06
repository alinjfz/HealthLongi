import XCTest
import PDFKit
@testable import HealthLongi

final class GPBriefPDFRendererTests: XCTestCase {
    func testRendersNonEmptyPDFData() {
        let brief = GPVisitBrief(
            reasonForVisit: "Discuss mood and labs.",
            discussionTopics: [],
            screeningScores: [],
            physicalMeasures: LifestyleSnapshot.from(.empty),
            abnormalLabs: [],
            allLabResults: nil,
            suggestedQuestions: ["How are my results?"],
            geneticsNote: nil,
            dataSourcesNote: "Based on screenings. Completeness 25%.",
            completenessPercent: 25,
            disclaimer: GPVisitBrief.standardDisclaimer,
            generatedAt: .now
        )

        let data = GPBriefPDFRenderer.render(brief)

        XCTAssertFalse(data.isEmpty)
    }

    func testPDFContainsDisclaimerText() throws {
        let brief = GPVisitBrief(
            reasonForVisit: "Test",
            discussionTopics: [],
            screeningScores: [],
            physicalMeasures: LifestyleSnapshot.from(.empty),
            abnormalLabs: [],
            allLabResults: nil,
            suggestedQuestions: [],
            geneticsNote: nil,
            dataSourcesNote: "Test sources",
            completenessPercent: 0,
            disclaimer: GPVisitBrief.standardDisclaimer,
            generatedAt: .now
        )

        let data = GPBriefPDFRenderer.render(brief)
        let pdf = PDFDocument(data: data)
        let text = pdf?.page(at: 0)?.string ?? ""

        XCTAssertTrue(text.contains("not a medical diagnosis"))
    }

    func testPDFPageCountAtLeastOne() {
        let brief = GPVisitBrief(
            reasonForVisit: "Test",
            discussionTopics: [],
            screeningScores: [],
            physicalMeasures: LifestyleSnapshot.from(.empty),
            abnormalLabs: [],
            allLabResults: nil,
            suggestedQuestions: [],
            geneticsNote: nil,
            dataSourcesNote: "Sources",
            completenessPercent: 0,
            disclaimer: GPVisitBrief.standardDisclaimer,
            generatedAt: .now
        )

        let data = GPBriefPDFRenderer.render(brief)
        let pdf = PDFDocument(data: data)

        XCTAssertGreaterThanOrEqual(pdf?.pageCount ?? 0, 1)
    }
}
