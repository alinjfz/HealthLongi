import XCTest
@testable import HealthLongi

final class GPBriefBuilderTests: XCTestCase {
    func testEmptyProfileGeneratesValidBriefWithDisclaimer() {
        let profile = UserProfile(onboardingComplete: true)

        let brief = GPBriefBuilder.build(
            profile: profile,
            assessment: nil,
            aiSummary: nil,
            snapshot: nil,
            prep: nil
        )

        XCTAssertFalse(brief.disclaimer.isEmpty)
        XCTAssertTrue(brief.discussionTopics.isEmpty)
        XCTAssertEqual(brief.reasonForVisit, "Routine GP visit — sharing recent health data.")
    }

    func testPHQ9AndGAD7AppearInScreeningWhenComplete() {
        let profile = UserProfile(
            onboardingComplete: true,
            phq9Score: 8,
            gad7Score: 6,
            phq9Complete: true,
            gad7Complete: true
        )

        let brief = GPBriefBuilder.build(
            profile: profile,
            assessment: nil,
            aiSummary: nil,
            snapshot: nil,
            prep: nil
        )

        XCTAssertEqual(brief.screeningScores.count, 2)
        XCTAssertEqual(brief.screeningScores.first?.kind, .phq9)
        XCTAssertEqual(brief.screeningScores.first?.band, "Mild")
    }

    func testMoodConcernPrioritisesMoodTopic() {
        var labs = LabResults(lastUpdated: .now)
        labs.ldlCholesterol = 4.5
        let profile = UserProfile(
            onboardingComplete: true,
            phq9Score: 12,
            gad7Score: 10,
            phq9Complete: true,
            gad7Complete: true,
            labResults: labs
        )
        let assessment = RiskAssessment(
            profile: AbstractedRiskProfile(
                cardioRisk: .moderate,
                mentalHealth: .moderateDepression,
                metabolic: .low,
                correlations: [],
                labSignals: LabRiskSignals(elevatedLipids: true)
            ),
            aiSummaryText: "Summary",
            phq9Score: 12,
            gad7Score: 10,
            metabolicScore: 1,
            cardioScore: 2
        )
        let prep = AppointmentPrepContext(
            selectedConcerns: [GPConcern.mood.rawValue],
            freeTextNotes: "",
            updatedAt: .now
        )

        let brief = GPBriefBuilder.build(
            profile: profile,
            assessment: assessment,
            aiSummary: nil,
            snapshot: nil,
            prep: prep
        )

        XCTAssertEqual(brief.discussionTopics.first?.signalID, GPConcern.mood.rawValue)
    }

    func testAbnormalLabsIncludedInBrief() {
        var labs = LabResults(lastUpdated: .now)
        labs.vitaminD = 18
        let profile = UserProfile(onboardingComplete: true, labResults: labs)

        let brief = GPBriefBuilder.build(
            profile: profile,
            assessment: nil,
            aiSummary: nil,
            snapshot: nil,
            prep: nil
        )

        XCTAssertEqual(brief.abnormalLabs.count, 1)
        XCTAssertEqual(brief.abnormalLabs.first?.biomarker, .vitaminD)
        XCTAssertNotNil(brief.allLabResults)
    }

    func testGeneticsNoteWhenFamilyHistoryPresent() {
        var profile = UserProfile(onboardingComplete: true)
        var genetics = GeneticsProfile.empty
        genetics.quizCompleted = true
        genetics.familyHeart = true
        profile.geneticsProfile = genetics

        let brief = GPBriefBuilder.build(
            profile: profile,
            assessment: nil,
            aiSummary: nil,
            snapshot: nil,
            prep: nil
        )

        XCTAssertEqual(brief.geneticsNote, "Family history / demo genetics data included for context only.")
    }
}
