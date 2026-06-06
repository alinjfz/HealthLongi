import XCTest
@testable import HealthLongi

final class AISafetyFilterTests: XCTestCase {
    func testYouHaveDiabetesBlocked() {
        XCTAssertTrue(AISafetyFilter.isBlocked("You have diabetes and should act now."))
    }

    func testTakeMetforminBlocked() {
        XCTAssertTrue(AISafetyFilter.isBlocked("Take metformin with meals."))
    }

    func testSleepAverageAllowed() {
        XCTAssertFalse(AISafetyFilter.isBlocked("Your sleep average is 5 hours this week."))
    }

    func testFilteredOutputFallsBackToTemplate() {
        let fallback = "Your sleep average is 5 hours this week."
        let blocked = "You have diabetes."
        let result = AISafetyFilter.sanitize(blocked, fallback: fallback)
        XCTAssertEqual(result, fallback)
    }
}
