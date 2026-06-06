import XCTest
@testable import HealthLongi

final class HealthKitPercentageTests: XCTestCase {
    func testFractionToDisplayPercent() {
        XCTAssertEqual(HealthKitPercentage.displayPercent(from: 0.97)!, 97, accuracy: 0.001)
        XCTAssertEqual(HealthKitPercentage.displayPercent(from: 0.98)!, 98, accuracy: 0.001)
        XCTAssertEqual(HealthKitPercentage.displayPercent(from: 1.0)!, 100, accuracy: 0.001)
    }

    func testAlreadyPercentUnchanged() {
        XCTAssertEqual(HealthKitPercentage.displayPercent(from: 97)!, 97, accuracy: 0.001)
        XCTAssertEqual(HealthKitPercentage.displayPercent(from: 98)!, 98, accuracy: 0.001)
    }

    func testNilReturnsNil() {
        XCTAssertNil(HealthKitPercentage.displayPercent(from: nil))
    }
}
