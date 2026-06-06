import XCTest
@testable import HealthLongi

final class CompletenessScoreCalculatorTests: XCTestCase {
    func testEmptyProfileZeroPercent() {
        let result = CompletenessScoreCalculator.calculate(
            profile: UserProfile(),
            snapshot: .empty
        )
        XCTAssertEqual(result.score, 0)
    }

    func testOnboardedOnlyDemographicsFifteenPercent() {
        let result = CompletenessScoreCalculator.calculate(
            profile: UserProfile(onboardingComplete: true),
            snapshot: .empty
        )
        XCTAssertEqual(result.score, 15)
    }

    func testPHQ9AndGAD7OnlyTwentyFivePercent() {
        let profile = UserProfile(
            phq9Complete: true,
            gad7Complete: true
        )
        let result = CompletenessScoreCalculator.calculate(profile: profile, snapshot: .empty)
        XCTAssertEqual(result.score, 25)
    }

    func testAllQuestionnairesHealthKitAndLabsOneHundred() {
        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.hasStepData = true
        snapshot.averageSleepHours = 7
        snapshot.averageRestingHeartRate = 65

        var labs = LabResults(lastUpdated: .now)
        labs.hba1c = 5.4
        labs.ldlCholesterol = 2.5
        labs.hdlCholesterol = 1.3
        labs.cholesterol = 4.5
        labs.vitaminD = 50

        let profile = UserProfile(
            onboardingComplete: true,
            phq9Complete: true,
            gad7Complete: true,
            who5Complete: true,
            pss10Complete: true,
            auditCComplete: true,
            phq15Complete: true,
            labResults: labs
        )

        let result = CompletenessScoreCalculator.calculate(profile: profile, snapshot: snapshot)
        XCTAssertEqual(result.score, 100)
    }

    func testPartialLabsIncompleteLabPortion() {
        var labs = LabResults(lastUpdated: .now)
        labs.hba1c = 5.4
        labs.ldlCholesterol = 2.5
        labs.vitaminD = 50

        let profile = UserProfile(onboardingComplete: true, labResults: labs)
        let result = CompletenessScoreCalculator.calculate(profile: profile, snapshot: .empty)

        XCTAssertTrue(result.missingItems.contains(.labBiomarkers))
        XCTAssertEqual(result.score, 15)
    }

    func testChecklistReturnsMissingItemIDs() {
        let profile = UserProfile(onboardingComplete: true)
        let result = CompletenessScoreCalculator.calculate(profile: profile, snapshot: .empty)

        XCTAssertTrue(result.missingItems.contains(.phq9))
        XCTAssertTrue(result.missingItems.contains(.gad7))
        XCTAssertTrue(result.missingItems.contains(.healthKitCore))
    }
}
