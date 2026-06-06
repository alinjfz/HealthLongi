import Foundation
import SwiftData

@MainActor
final class AssessmentOrchestrator {
    private let healthDataProvider: any HealthDataProviding
    private let riskCalculator: any RiskCalculating
    private let aiSummarizer: any AISummarizing

    init(
        healthDataProvider: any HealthDataProviding,
        riskCalculator: any RiskCalculating,
        aiSummarizer: any AISummarizing
    ) {
        self.healthDataProvider = healthDataProvider
        self.riskCalculator = riskCalculator
        self.aiSummarizer = aiSummarizer
    }

    struct AssessmentRunResult: Sendable {
        var assessment: RiskAssessment
        var summary: AISummaryResult
    }

    func runAssessment(profile: UserProfile, modelContext: ModelContext) async throws -> AssessmentRunResult {
        let snapshot = await fetchSnapshotWithFallback()

        let input = AssessmentInput(
            demographics: profile.demographics,
            weeklySteps: snapshot.averageDailySteps,
            priorWeeklySteps: snapshot.priorAverageDailySteps,
            restingHeartRate: snapshot.averageRestingHeartRate,
            sleepHoursAvg: snapshot.averageSleepHours,
            phq9Score: profile.phq9Score,
            gad7Score: profile.gad7Score,
            bmi: profile.bmi,
            physicalActivityMinutes: profile.physicalActivityMinutes
        )

        let scoring = riskCalculator.calculate(input: input)
        let summary = try await aiSummarizer.summarize(profile: scoring.profile)

        let assessment = RiskAssessment(
            profile: scoring.profile,
            aiSummaryText: summary.markdownSummary,
            phq9Score: scoring.phq9Score,
            gad7Score: scoring.gad7Score,
            metabolicScore: scoring.metabolicScore,
            cardioScore: scoring.cardioScore,
            usedAIFallback: summary.usedFallback
        )

        modelContext.insert(assessment)
        try modelContext.save()

        return AssessmentRunResult(assessment: assessment, summary: summary)
    }

    func requestHealthAuthorization() async throws {
        do {
            try await healthDataProvider.requestAuthorization()
        } catch {
            // HealthKit unavailable on simulator — continue with manual/mock data.
        }
    }

    private func fetchSnapshotWithFallback() async -> WeeklyHealthSnapshot {
        do {
            return try await healthDataProvider.fetchWeeklySnapshot()
        } catch {
            return MockHealthDataProvider().snapshot
        }
    }
}
