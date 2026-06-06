import XCTest
@testable import HealthLongi

final class LabFlagEvaluatorTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testHbA1c62FlaggedAbove() {
        var labs = LabResults(lastUpdated: referenceDate)
        labs.hba1c = 6.2

        let flags = LabFlagEvaluator.evaluate(labs: labs, at: referenceDate)

        XCTAssertEqual(flags.count, 1)
        XCTAssertEqual(flags[0].biomarker, .hba1c)
        XCTAssertEqual(flags[0].direction, .above)
        XCTAssertEqual(flags[0].value, 6.2)
    }

    func testLDL25NotFlagged() {
        var labs = LabResults(lastUpdated: referenceDate)
        labs.ldlCholesterol = 2.5

        let flags = LabFlagEvaluator.evaluate(labs: labs, at: referenceDate)

        XCTAssertTrue(flags.isEmpty)
    }

    func testVitaminD22FlaggedBelow() {
        var labs = LabResults(lastUpdated: referenceDate)
        labs.vitaminD = 22

        let flags = LabFlagEvaluator.evaluate(labs: labs, at: referenceDate)

        XCTAssertEqual(flags.count, 1)
        XCTAssertEqual(flags[0].biomarker, .vitaminD)
        XCTAssertEqual(flags[0].direction, .below)
        XCTAssertEqual(flags[0].value, 22)
    }

    func testMissingValueProducesNoFlag() {
        let labs = LabResults(lastUpdated: referenceDate)

        let flags = LabFlagEvaluator.evaluate(labs: labs, at: referenceDate)

        XCTAssertTrue(flags.isEmpty)
    }

    func testBloodPressure145Over92Flagged() {
        var labs = LabResults(lastUpdated: referenceDate)
        labs.bloodPressureSystolic = 145
        labs.bloodPressureDiastolic = 92

        let flags = LabFlagEvaluator.evaluate(labs: labs, at: referenceDate)

        XCTAssertEqual(flags.count, 2)
        XCTAssertTrue(flags.contains { $0.biomarker == .bloodPressureSystolic && $0.direction == .above })
        XCTAssertTrue(flags.contains { $0.biomarker == .bloodPressureDiastolic && $0.direction == .above })
    }

    func testReferenceRangesMatchNHSHints() {
        XCTAssertEqual(LabBiomarker.hba1c.referenceRange?.nhsLabel, "Non-diabetic: below 6.0%")
        XCTAssertEqual(LabBiomarker.cholesterol.referenceRange?.max, 5.0)
        XCTAssertEqual(LabBiomarker.vitaminD.referenceRange?.min, 25)
    }
}
