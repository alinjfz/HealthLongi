import Foundation
import SwiftData

@Model
final class RiskAssessment {
    var timestamp: Date
    var cardioRiskRaw: String
    var mentalHealthRaw: String
    var metabolicRaw: String
    var correlationsJSON: String
    var labSignalsJSON: String?
    var aiSummaryText: String
    var aiInsightJSON: String?
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
        usedAIFallback: Bool = false,
        aiInsightJSON: String? = nil
    ) {
        self.timestamp = timestamp
        self.cardioRiskRaw = profile.cardioRisk.rawValue
        self.mentalHealthRaw = profile.mentalHealth.rawValue
        self.metabolicRaw = profile.metabolic.rawValue
        self.correlationsJSON = (try? String(
            data: JSONEncoder().encode(profile.correlations),
            encoding: .utf8
        )) ?? "[]"
        self.labSignalsJSON = try? String(
            data: JSONEncoder().encode(profile.labSignals),
            encoding: .utf8
        )
        self.aiSummaryText = aiSummaryText
        self.aiInsightJSON = aiInsightJSON
        self.phq9Score = phq9Score
        self.gad7Score = gad7Score
        self.metabolicScore = metabolicScore
        self.cardioScore = cardioScore
        self.usedAIFallback = usedAIFallback
    }

    var aiInsight: AISummaryResult? {
        AIInsightCodec.decode(from: aiInsightJSON)
    }

    var abstractedProfile: AbstractedRiskProfile {
        let correlations: [String]
        if let data = correlationsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            correlations = decoded
        } else {
            correlations = []
        }

        let labSignals: LabRiskSignals
        if let labSignalsJSON,
           let data = labSignalsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(LabRiskSignals.self, from: data) {
            labSignals = decoded
        } else {
            labSignals = .empty
        }

        return AbstractedRiskProfile(
            cardioRisk: RiskLevel(rawValue: cardioRiskRaw) ?? .low,
            mentalHealth: MentalFlag(rawValue: mentalHealthRaw) ?? .none,
            metabolic: RiskLevel(rawValue: metabolicRaw) ?? .low,
            correlations: correlations,
            labSignals: labSignals
        )
    }
}
