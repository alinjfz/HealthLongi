import Foundation

enum AIHealthContextBuilder {
    static func build(
        profile: UserProfile,
        snapshot: WeeklyHealthSnapshot,
        trends: TrendDigest,
        scoring: ScoringResult,
        priorAssessment: RiskAssessment?
    ) -> AIHealthContext {
        var base = AIHealthContext(
            demographics: AIDemographics(
                age: profile.age,
                sex: profile.sex,
                smokingStatus: profile.smokingStatus
            ),
            healthKit: AIHealthKitMetrics(
                averageDailySteps: snapshot.averageDailySteps,
                priorAverageDailySteps: snapshot.priorAverageDailySteps,
                averageRestingHeartRate: snapshot.averageRestingHeartRate,
                averageSleepHours: snapshot.averageSleepHours,
                heartRateVariability: snapshot.heartRateVariability,
                oxygenSaturation: snapshot.oxygenSaturation,
                activeEnergyKcalPerDay: snapshot.activeEnergyBurned,
                distanceKmPerDay: snapshot.distanceWalkingRunning,
                weeklyExerciseMinutes: snapshot.weeklyExerciseMinutes,
                mindfulMinutesPerDay: snapshot.mindfulMinutes,
                bodyMassKg: snapshot.bodyMass,
                heightMetres: snapshot.height,
                bmi: snapshot.bmi ?? profile.bmi,
                bodyFatPercent: snapshot.bodyFatPercentage,
                fetchedAt: snapshot.fetchedAt
            ),
            trends: trends,
            questionnaires: AIQuestionnaireScores(
                phq9: profile.phq9Complete ? profile.phq9Score : nil,
                gad7: profile.gad7Complete ? profile.gad7Score : nil,
                who5: profile.who5Complete ? profile.who5Score : nil,
                pss10: profile.pss10Complete ? profile.pss10Score : nil,
                phq15: profile.phq15Complete ? profile.phq15Score : nil,
                auditC: profile.auditCComplete ? profile.auditCScore : nil
            ),
            labs: profile.labResults,
            ruleProfile: scoring.profile,
            ruleScores: AIRuleScores(
                cardioScore: scoring.cardioScore,
                metabolicScore: scoring.metabolicScore,
                phq9Score: scoring.phq9Score,
                gad7Score: scoring.gad7Score
            ),
            priorAssessment: priorAssessment.map(priorSnapshot),
            nhsTopics: []
        )

        base.nhsTopics = NHSKnowledgeSelector.topics(for: base)
        return base
    }

    private static func priorSnapshot(_ assessment: RiskAssessment) -> AIPriorAssessment {
        AIPriorAssessment(
            assessedAt: assessment.timestamp,
            cardioRisk: assessment.abstractedProfile.cardioRisk,
            mentalHealth: assessment.abstractedProfile.mentalHealth,
            metabolic: assessment.abstractedProfile.metabolic,
            phq9Score: assessment.phq9Score,
            gad7Score: assessment.gad7Score
        )
    }
}
