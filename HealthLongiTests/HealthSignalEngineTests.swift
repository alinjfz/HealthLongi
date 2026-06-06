import XCTest
@testable import HealthLongi

final class HealthSignalEngineTests: XCTestCase {
    func testSleepAnxietyFiresWithGAD7AndLowSleep() {
        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.averageSleepHours = 5

        let input = SignalEngineInput(
            phq9Score: 0,
            gad7Score: 12,
            who5Score: 0,
            pss10Score: 0,
            auditCScore: 0,
            phq15Score: 0,
            bmi: nil,
            snapshot: snapshot,
            priorSnapshot: nil,
            labFlags: [],
            labResults: nil,
            priorRestingHeartRate: nil
        )

        let signals = HealthSignalEngine.evaluate(input)

        XCTAssertTrue(signals.contains { $0.id == "sleep_anxiety" })
    }

    func testMetabolicLifestyleFiresWithHbA1cLowStepsAndBMI() {
        var labs = LabResults(lastUpdated: .now)
        labs.hba1c = 6.5

        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.averageDailySteps = 3000

        let input = SignalEngineInput(
            phq9Score: 0,
            gad7Score: 0,
            who5Score: 0,
            pss10Score: 0,
            auditCScore: 0,
            phq15Score: 0,
            bmi: 28,
            snapshot: snapshot,
            priorSnapshot: nil,
            labFlags: LabFlagEvaluator.evaluate(labs: labs),
            labResults: labs,
            priorRestingHeartRate: nil
        )

        let signals = HealthSignalEngine.evaluate(input)

        XCTAssertTrue(signals.contains { $0.id == "metabolic_lifestyle" })
    }

    func testEmptyProfileProducesZeroSignals() {
        let signals = HealthSignalEngine.evaluate(.empty)
        XCTAssertTrue(signals.isEmpty)
    }

    func testSixTriggersReturnsTopFiveWithDiscussWithGPFirst() {
        var labs = LabResults(lastUpdated: .now)
        labs.hba1c = 6.5
        labs.ldlCholesterol = 4.0
        labs.bloodPressureSystolic = 145
        labs.bloodPressureDiastolic = 92

        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.averageDailySteps = 3000

        let labFlags = LabFlagEvaluator.evaluate(labs: labs)

        let input = SignalEngineInput(
            phq9Score: 12,
            gad7Score: 12,
            who5Score: 8,
            pss10Score: 22,
            auditCScore: 6,
            phq15Score: 12,
            bmi: 28,
            snapshot: snapshot,
            priorSnapshot: nil,
            labFlags: labFlags,
            labResults: labs,
            priorRestingHeartRate: nil
        )

        let signals = HealthSignalEngine.evaluate(input)

        XCTAssertEqual(signals.count, 5)
        XCTAssertEqual(signals.first?.severity, .discussWithGP)
        XCTAssertTrue(signals.filter { $0.severity == .discussWithGP }.count >= 1)
    }

    func testEachSignalHasEvidence() {
        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.averageSleepHours = 5

        let input = SignalEngineInput(
            phq9Score: 0,
            gad7Score: 12,
            who5Score: 0,
            pss10Score: 0,
            auditCScore: 0,
            phq15Score: 0,
            bmi: nil,
            snapshot: snapshot,
            priorSnapshot: nil,
            labFlags: [],
            labResults: nil,
            priorRestingHeartRate: nil
        )

        let signals = HealthSignalEngine.evaluate(input)

        for signal in signals {
            XCTAssertFalse(signal.evidence.isEmpty, "Signal \(signal.id) missing evidence")
        }
    }
}
