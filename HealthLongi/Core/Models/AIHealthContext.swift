import Foundation

/// Full health picture sent to AI. No names, emails, or free-text identity fields.
struct AIHealthContext: Codable, Sendable, Equatable {
    var demographics: AIDemographics
    var healthKit: AIHealthKitMetrics
    var trends: TrendDigest
    var questionnaires: AIQuestionnaireScores
    var labs: LabResults?
    var ruleProfile: AbstractedRiskProfile
    var ruleScores: AIRuleScores
    var priorAssessment: AIPriorAssessment?
    var nhsTopics: [NHSKnowledgeTopic]
}

struct AIDemographics: Codable, Sendable, Equatable {
    var age: Int
    var sex: Sex
    var smokingStatus: SmokingStatus
}

struct AIHealthKitMetrics: Codable, Sendable, Equatable {
    var averageDailySteps: Int
    var priorAverageDailySteps: Int?
    var averageRestingHeartRate: Double?
    var averageSleepHours: Double?
    var heartRateVariability: Double?
    var oxygenSaturation: Double?
    var activeEnergyKcalPerDay: Double?
    var distanceKmPerDay: Double?
    var weeklyExerciseMinutes: Int?
    var mindfulMinutesPerDay: Double?
    var bodyMassKg: Double?
    var heightMetres: Double?
    var bmi: Double?
    var bodyFatPercent: Double?
    var fetchedAt: Date
}

struct AIQuestionnaireScores: Codable, Sendable, Equatable {
    var phq9: Int?
    var gad7: Int?
    var who5: Int?
    var pss10: Int?
    var phq15: Int?
    var auditC: Int?
}

struct AIRuleScores: Codable, Sendable, Equatable {
    var cardioScore: Int
    var metabolicScore: Int
    var phq9Score: Int
    var gad7Score: Int
}

struct AIPriorAssessment: Codable, Sendable, Equatable {
    var assessedAt: Date
    var cardioRisk: RiskLevel
    var mentalHealth: MentalFlag
    var metabolic: RiskLevel
    var phq9Score: Int
    var gad7Score: Int
}

struct TrendDigest: Codable, Sendable, Equatable {
    var steps: TrendMetricDigest?
    var sleep: TrendMetricDigest?
    var restingHeartRate: TrendMetricDigest?

    static let empty = TrendDigest()
}

struct TrendMetricDigest: Codable, Sendable, Equatable {
    var recentAverage: Double
    var priorAverage: Double
    var changePercent: Double
    var direction: TrendDirection
    var dayCount: Int
}

enum TrendDirection: String, Codable, Sendable {
    case rising
    case falling
    case stable
}
