import Foundation

enum NHSKnowledgeSelector {
    static func topics(for context: AIHealthContext) -> [NHSKnowledgeTopic] {
        var ids = Set<String>()
        ids.insert("find_gp")

        let q = context.questionnaires
        let labs = context.labs
        let hk = context.healthKit
        let profile = context.ruleProfile

        if (q.phq9 ?? 0) >= 5 { ids.insert("depression"); ids.insert("nhs_mental_health") }
        if (q.phq9 ?? 0) >= 10 { ids.insert("nhs_talking_therapies") }
        if (q.phq9 ?? 0) >= 15 || profile.mentalHealth == .severeDepression { ids.insert("nhs_111") }

        if (q.gad7 ?? 0) >= 5 { ids.insert("anxiety"); ids.insert("nhs_mental_health") }
        if (q.gad7 ?? 0) >= 10 { ids.insert("nhs_talking_therapies") }
        if (q.gad7 ?? 0) >= 15 || profile.mentalHealth == .highAnxiety { ids.insert("nhs_111") }

        if (q.who5 ?? 25) <= 13 || (q.pss10 ?? 0) >= 14 { ids.insert("stress_wellbeing") }

        if profile.cardioRisk != .low || profile.labSignals.elevatedLipids || profile.labSignals.elevatedBloodPressure {
            ids.insert("nhs_heart_health")
        }
        if profile.labSignals.elevatedLipids { ids.insert("high_cholesterol") }
        if profile.labSignals.elevatedBloodPressure { ids.insert("high_blood_pressure") }

        if profile.metabolic != .low || profile.labSignals.elevatedGlucose || profile.labSignals.elevatedWaist {
            ids.insert("nhs_diabetes_prevention")
            ids.insert("nhs_healthy_weight")
        }

        if let bmi = hk.bmi, bmi >= 25 { ids.insert("nhs_healthy_weight") }
        if (q.auditC ?? 0) >= 4 { ids.insert("alcohol") }
        if profile.labSignals.lowVitamins { ids.insert("vitamin_d") }

        let steps = hk.averageDailySteps
        if steps < 7000 || context.trends.steps?.direction == .falling {
            ids.insert("physical_activity")
            ids.insert("nhs_active_10")
        }

        if let sleep = hk.averageSleepHours, sleep < 7 || context.trends.sleep?.direction == .falling {
            ids.insert("sleep")
        }

        if !profile.correlations.isEmpty && profile.correlations.contains(where: { $0.contains("sleep") || $0.contains("stress") }) {
            ids.insert("sleep")
            ids.insert("stress_wellbeing")
        }

        return NHSKnowledgeBase.all.filter { ids.contains($0.id) }
    }
}
