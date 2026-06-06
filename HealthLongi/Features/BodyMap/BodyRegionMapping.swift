import SwiftUI

enum BodyRegionMapping {
    static func color(
        for region: BodyRegion,
        profile: AbstractedRiskProfile,
        snapshot: WeeklyHealthSnapshot,
        signals: [HealthSignal] = []
    ) -> Color {
        if !signals.isEmpty {
            return BodyMapSignalMapper.color(for: region, signals: signals)
        }

        switch region {
        case .brain:
            return NHSTheme.mentalColor(for: profile.mentalHealth)
        case .heart:
            return NHSTheme.riskColor(for: profile.cardioRisk)
        case .lungs:
            guard let spo2 = snapshot.oxygenSaturation else {
                return NHSTheme.riskColor(for: profile.cardioRisk)
            }
            if spo2 >= 95 { return .green }
            if spo2 >= 90 { return .orange }
            return .red
        case .abdomen:
            return NHSTheme.riskColor(for: profile.metabolic)
        case .leftShoulder, .rightHip, .leftKnee:
            return profile.phq15RiskColor
        }
    }
}

private extension AbstractedRiskProfile {
    var phq15RiskColor: Color {
        switch mentalHealth {
        case .none, .mild: .green
        case .moderateDepression, .moderateAnxiety: .orange
        case .severeDepression, .highAnxiety: .red
        }
    }
}
