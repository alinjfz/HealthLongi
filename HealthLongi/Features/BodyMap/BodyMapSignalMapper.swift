import SwiftUI

enum BodyMapSignalMapper {
    static func color(for region: BodyRegion, signals allSignals: [HealthSignal]) -> Color {
        let regionSignals = signals(for: region, from: allSignals)
        guard let highest = regionSignals.map(\.severity).max(by: { severityRank($0) < severityRank($1) }) else {
            return .gray.opacity(0.35)
        }
        return color(for: highest)
    }

    static func signals(for region: BodyRegion, from allSignals: [HealthSignal]) -> [HealthSignal] {
        allSignals.filter { mappedRegion(for: $0) == region }
    }

    static func signalIDs(for region: BodyRegion) -> [String] {
        switch region {
        case .brain:
            ["stress_somatic", "alcohol_mood", "wellbeing_dip", "activity_mood", "sleep_anxiety"]
        case .heart:
            ["recovery_concern", "lipid_flag", "bp_elevated"]
        case .lungs:
            ["stress_somatic"]
        case .abdomen:
            ["metabolic_lifestyle", "alcohol_mood", "vitamin_d_low"]
        case .leftShoulder, .rightHip, .leftKnee:
            ["activity_mood", "metabolic_lifestyle"]
        }
    }

    static func mappedRegion(for signal: HealthSignal) -> BodyRegion? {
        if let bodyRegion = signal.bodyRegion {
            switch bodyRegion {
            case .leftShoulder, .rightHip, .leftKnee:
                return bodyRegion
            default:
                return bodyRegion
            }
        }
        return signalRegionMap[signal.id]
    }

    private static let signalRegionMap: [String: BodyRegion] = [
        "metabolic_lifestyle": .abdomen,
        "stress_somatic": .brain,
        "alcohol_mood": .abdomen,
        "recovery_concern": .heart,
        "lipid_flag": .heart,
        "wellbeing_dip": .brain,
        "activity_mood": .leftKnee,
        "sleep_anxiety": .brain,
        "bp_elevated": .heart,
        "vitamin_d_low": .abdomen
    ]

    private static func color(for severity: HealthSignal.Severity) -> Color {
        switch severity {
        case .discussWithGP: .red
        case .watch: .orange
        case .info: .green
        }
    }

    private static func severityRank(_ severity: HealthSignal.Severity) -> Int {
        switch severity {
        case .discussWithGP: 3
        case .watch: 2
        case .info: 1
        }
    }
}
