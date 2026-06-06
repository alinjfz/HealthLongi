import XCTest
@testable import HealthLongi

final class LabReportOCRServiceTests: XCTestCase {
    private let sampleReport = """
    | Investigation | Result | Units | Reference Range |
    | Haemoglobin | 147 | g/L | 130 - 180 |
    | LDL Cholesterol | 2.8 | mmol/L | <3.0 |
    | HbA1c | 36 | mmol/mol | 20 - 41 |
    | TSH | 2.1 | mIU/L | 0.3 - 4.2 |
    """

    func testParsesNHSStyleTextReport() {
        let parsed = LabReportOCRService.parseReportText(sampleReport)
        let markers = Set(parsed.map(\.marker))

        XCTAssertTrue(markers.contains(.hemoglobin), "Expected haemoglobin in \(markers)")
        XCTAssertTrue(markers.contains(.ldlCholesterol), "Expected LDL in \(markers)")
        XCTAssertTrue(markers.contains(.hba1c))
        XCTAssertTrue(markers.contains(.tsh))

        let hb = parsed.first { $0.marker == .hemoglobin }
        XCTAssertNotNil(hb)
        XCTAssertEqual(hb!.value, 147, accuracy: 0.01)
    }
}
