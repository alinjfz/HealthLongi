import XCTest
@testable import HealthLongi

final class RiskCalculatorTests: XCTestCase {
    let calculator = RiskCalculator()

    func testPHQ9Score9IsNotModerateDepression() {
        let input = makeInput(phq9: 9, gad7: 0)
        let result = calculator.calculate(input: input)
        XCTAssertNotEqual(result.profile.mentalHealth, .moderateDepression)
        XCTAssertNotEqual(result.profile.mentalHealth, .severeDepression)
    }

    func testPHQ9Score10IsModerateDepression() {
        let input = makeInput(phq9: 10, gad7: 0)
        let result = calculator.calculate(input: input)
        XCTAssertEqual(result.profile.mentalHealth, .moderateDepression)
    }

    func testGAD7Score15IsHighAnxiety() {
        let input = makeInput(phq9: 0, gad7: 15)
        let result = calculator.calculate(input: input)
        XCTAssertEqual(result.profile.mentalHealth, .highAnxiety)
    }

    func testDroppingStepsWithHighGAD7AddsCorrelation() {
        let input = AssessmentInput(
            demographics: Demographics(age: 30, sex: .female, smokingStatus: .never),
            weeklySteps: 4000,
            priorWeeklySteps: 8000,
            restingHeartRate: 72,
            sleepHoursAvg: 7,
            phq9Score: 5,
            gad7Score: 12,
            bmi: 24,
            physicalActivityMinutes: 30
        )
        let result = calculator.calculate(input: input)
        XCTAssertTrue(result.profile.correlations.contains("dropping_steps_with_high_gad7"))
    }

    func testAbstractedProfileJSONContainsNoRawPII() {
        let input = makeInput(phq9: 12, gad7: 11)
        let result = calculator.calculate(input: input)
        let data = try! JSONEncoder().encode(result.profile)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertFalse(json.contains("30"))
        XCTAssertFalse(json.contains("bmi"))
        XCTAssertFalse(json.contains("phq9"))
        XCTAssertFalse(json.contains("gad7"))
        XCTAssertFalse(json.contains("age"))
    }

    func testHighMetabolicRiskForObeseSedentaryOlderAdult() {
        let input = AssessmentInput(
            demographics: Demographics(age: 65, sex: .male, smokingStatus: .never),
            weeklySteps: 1500,
            priorWeeklySteps: 2000,
            restingHeartRate: 75,
            sleepHoursAvg: 6,
            phq9Score: 3,
            gad7Score: 2,
            bmi: 35,
            physicalActivityMinutes: 0
        )
        let result = calculator.calculate(input: input)
        XCTAssertEqual(result.profile.metabolic, .high)
    }

    private func makeInput(phq9: Int, gad7: Int) -> AssessmentInput {
        AssessmentInput(
            demographics: Demographics(age: 30, sex: .female, smokingStatus: .never),
            weeklySteps: 6000,
            priorWeeklySteps: 6500,
            restingHeartRate: 68,
            sleepHoursAvg: 7,
            phq9Score: phq9,
            gad7Score: gad7,
            bmi: 24,
            physicalActivityMinutes: 90
        )
    }
}
