import XCTest
@testable import HealthLongi

final class AbstractedRiskProfileTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let profile = AbstractedRiskProfile(
            cardioRisk: .moderate,
            mentalHealth: .highAnxiety,
            metabolic: .low,
            correlations: ["dropping_steps_with_high_gad7"],
            labSignals: .empty
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(AbstractedRiskProfile.self, from: data)

        XCTAssertEqual(decoded, profile)
    }

    func testRiskAssessmentRoundTrip() {
        let profile = AbstractedRiskProfile(
            cardioRisk: .high,
            mentalHealth: .moderateDepression,
            metabolic: .moderate,
            correlations: ["poor_sleep_with_elevated_depression"],
            labSignals: .empty
        )

        let assessment = RiskAssessment(
            profile: profile,
            aiSummaryText: "Test summary",
            phq9Score: 12,
            gad7Score: 8,
            metabolicScore: 9,
            cardioScore: 11
        )

        XCTAssertEqual(assessment.abstractedProfile, profile)
    }

    func testNHSLinksForHighAnxietyProfile() {
        let profile = AbstractedRiskProfile(
            cardioRisk: .low,
            mentalHealth: .highAnxiety,
            metabolic: .low,
            correlations: [],
            labSignals: .empty
        )

        let links = NHSLinks.links(for: profile)
        XCTAssertTrue(links.contains { $0.id == "nhs_talking_therapies" })
    }
}
