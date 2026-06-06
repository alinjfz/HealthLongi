import Foundation

/// Anonymized risk profile sent to GLM — must never include raw lab results or genetics data.
struct AbstractedRiskProfile: Codable, Sendable, Equatable {
    var cardioRisk: RiskLevel
    var mentalHealth: MentalFlag
    var metabolic: RiskLevel
    var correlations: [String]
    var labSignals: LabRiskSignals

    static let placeholder = AbstractedRiskProfile(
        cardioRisk: .low,
        mentalHealth: .none,
        metabolic: .low,
        correlations: [],
        labSignals: .empty
    )
}
