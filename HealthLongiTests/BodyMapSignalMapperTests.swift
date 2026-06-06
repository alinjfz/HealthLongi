import XCTest
import SwiftUI
@testable import HealthLongi

final class BodyMapSignalMapperTests: XCTestCase {
    func testHeartRegionWithLipidFlagDiscussWithGPUsesRedTier() {
        let signal = makeSignal(id: "lipid_flag", severity: .discussWithGP, region: .heart)
        let color = BodyMapSignalMapper.color(for: .heart, signals: [signal])
        XCTAssertEqual(color, .red)
    }

    func testBrainWithNoSignalsUsesNeutralColor() {
        let color = BodyMapSignalMapper.color(for: .brain, signals: [])
        XCTAssertEqual(color, .gray.opacity(0.35))
    }

    func testAbdomenMultipleSignalsHighestSeverityWins() {
        let watch = makeSignal(id: "vitamin_d_low", severity: .watch, region: .abdomen)
        let gp = makeSignal(id: "metabolic_lifestyle", severity: .discussWithGP, region: .abdomen)
        let color = BodyMapSignalMapper.color(for: .abdomen, signals: [watch, gp])
        XCTAssertEqual(color, .red)
    }

    func testRegionTapPayloadReturnsCorrectSignalIDs() {
        let signals = [
            makeSignal(id: "lipid_flag", severity: .discussWithGP, region: .heart),
            makeSignal(id: "sleep_anxiety", severity: .watch, region: .brain)
        ]

        let heartSignals = BodyMapSignalMapper.signals(for: .heart, from: signals)
        XCTAssertEqual(heartSignals.map(\.id), ["lipid_flag"])
    }

    private func makeSignal(id: String, severity: HealthSignal.Severity, region: BodyRegion) -> HealthSignal {
        HealthSignal(
            id: id,
            kind: .labFlag,
            title: id,
            detail: "Detail",
            evidence: [EvidenceItem(source: .lab, label: "Test", value: "1")],
            suggestedQuestions: [],
            severity: severity,
            bodyRegion: region,
            createdAt: .now
        )
    }
}
