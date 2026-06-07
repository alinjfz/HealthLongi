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
        profile.syncMetabolicData(from: snapshot)

        let input = AssessmentInput(
            demographics: profile.demographics,
            weeklySteps: snapshot.averageDailySteps,
            priorWeeklySteps: snapshot.priorAverageDailySteps,
            restingHeartRate: snapshot.averageRestingHeartRate,
            sleepHoursAvg: snapshot.averageSleepHours,
            phq9Score: profile.phq9Score,
            gad7Score: profile.gad7Score,
            bmi: profile.bmi,
            physicalActivityMinutes: profile.physicalActivityMinutes,
            labSignals: LabRiskSignals.from(labs: profile.labResults),
            who5Score: profile.who5Complete ? profile.who5Score : nil,
            pss10Score: profile.pss10Complete ? profile.pss10Score : nil,
            phq15Score: profile.phq15Complete ? profile.phq15Score : nil,
            auditCScore: profile.auditCComplete ? profile.auditCScore : nil
        )

        let scoring = riskCalculator.calculate(input: input)
        let priorAssessment = fetchLatestAssessment(modelContext: modelContext)
        let trends = await fetchTrendDigest()
        let context = AIHealthContextBuilder.build(
            profile: profile,
            snapshot: snapshot,
            trends: trends,
            scoring: scoring,
            priorAssessment: priorAssessment
        )
        let summary = try await aiSummarizer.summarize(context: context)

        let assessment = RiskAssessment(
            profile: scoring.profile,
            aiSummaryText: summary.markdownSummary,
            phq9Score: scoring.phq9Score,
            gad7Score: scoring.gad7Score,
            metabolicScore: scoring.metabolicScore,
            cardioScore: scoring.cardioScore,
            usedAIFallback: summary.usedFallback,
            aiInsightJSON: AIInsightCodec.encode(summary)
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

    private func fetchTrendDigest() async -> TrendDigest {
        let metrics: [HealthKitMetric] = [.steps, .sleep, .restingHeartRate]
        var series: [HealthKitMetric: [DailyDataPoint]] = [:]
        for metric in metrics {
            if let points = try? await healthDataProvider.fetchDailySeries(for: metric, days: 30) {
                series[metric] = points
            }
        }
        return TrendDigestBuilder.build(from: series)
    }

    private func fetchLatestAssessment(modelContext: ModelContext) -> RiskAssessment? {
        var descriptor = FetchDescriptor<RiskAssessment>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
