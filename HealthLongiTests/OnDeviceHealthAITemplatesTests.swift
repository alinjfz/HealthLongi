import XCTest
@testable import HealthLongi

final class OnDeviceHealthAITemplatesTests: XCTestCase {
    func testEverySignalIDHasNonEmptyTemplate() {
        for signalID in OnDeviceHealthAITemplates.signalIDs {
            let signal = HealthSignal(
                id: signalID,
                kind: .correlation,
                title: signalID,
                detail: "Detail",
                evidence: [EvidenceItem(source: .screening, label: "Test", value: "1")],
                suggestedQuestions: [],
                severity: .watch,
                bodyRegion: nil,
                createdAt: .now
            )

            let template = OnDeviceHealthAITemplates.explainSignal(signal)
            XCTAssertFalse(template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Missing template for \(signalID)")
        }
    }

    func testTemplatesContainNoBannedPatterns() {
        for signalID in OnDeviceHealthAITemplates.signalIDs {
            let signal = HealthSignal(
                id: signalID,
                kind: .correlation,
                title: signalID,
                detail: "Detail",
                evidence: [],
                suggestedQuestions: [],
                severity: .watch,
                bodyRegion: nil,
                createdAt: .now
            )

            let template = OnDeviceHealthAITemplates.explainSignal(signal)
            XCTAssertFalse(AISafetyFilter.isBlocked(template), "Template for \(signalID) contains banned pattern")
        }
    }
}
