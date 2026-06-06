import Foundation
import SwiftData

@Model
final class RiskAssessment {
    var timestamp: Date
    var cardioRiskRaw: String
    var mentalHealthRaw: String
    var metabolicRaw: String
    var correlationsJSON: String
    var aiSummaryText: String
    var phq9Score: Int
    var gad7Score: Int
    var metabolicScore: Int
    var cardioScore: Int
    var usedAIFallback: Bool

    init(
        timestamp: Date = .now,
        profile: AbstractedRiskProfile,
        aiSummaryText: String,
        phq9Score: Int,
        gad7Score: Int,
        metabolicScore: Int,
        cardioScore: Int,
        usedAIFallback: Bool = false
    ) {
        self.timestamp = timestamp
        self.cardioRiskRaw = profile.cardioRisk.rawValue
        self.mentalHealthRaw = profile.mentalHealth.rawValue
        self.metabolicRaw = profile.metabolic.rawValue
        self.correlationsJSON = (try? String(
            data: JSONEncoder().encode(profile.correlations),
            encoding: .utf8
        )) ?? "[]"
        self.aiSummaryText = aiSummaryText
        self.phq9Score = phq9Score
        self.gad7Score = gad7Score
        self.metabolicScore = metabolicScore
        self.cardioScore = cardioScore
        self.usedAIFallback = usedAIFallback
    }

    var abstractedProfile: AbstractedRiskProfile {
        let correlations: [String]
        if let data = correlationsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            correlations = decoded
        } else {
            correlations = []
        }

        return AbstractedRiskProfile(
            cardioRisk: RiskLevel(rawValue: cardioRiskRaw) ?? .low,
            mentalHealth: MentalFlag(rawValue: mentalHealthRaw) ?? .none,
            metabolic: RiskLevel(rawValue: metabolicRaw) ?? .low,
            correlations: correlations
        )
    }
}
