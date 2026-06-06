import Foundation

struct AbstractedRiskProfile: Codable, Sendable, Equatable {
    var cardioRisk: RiskLevel
    var mentalHealth: MentalFlag
    var metabolic: RiskLevel
    var correlations: [String]

    static let placeholder = AbstractedRiskProfile(
        cardioRisk: .low,
        mentalHealth: .none,
        metabolic: .low,
        correlations: []
    )
}
