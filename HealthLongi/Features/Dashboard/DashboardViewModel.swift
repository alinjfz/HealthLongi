import Foundation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
    var isLoading = false
    var errorMessage: String?
    var latestAssessment: RiskAssessment?
    var latestSummary: AISummaryResult?
    var healthSnapshot: WeeklyHealthSnapshot?
    var selectedTips: [HealthTip] = []
    var motivationalQuote: MotivationalQuote = MotivationalQuotes.random()
    var completedTipIDs: Set<String> = []

    private let healthDataProvider: (any HealthDataProviding)?

    init(healthDataProvider: (any HealthDataProviding)? = nil) {
        self.healthDataProvider = healthDataProvider
    }

    func loadLatest(from assessments: [RiskAssessment]) {
        latestAssessment = assessments.sorted { $0.timestamp > $1.timestamp }.first
        if let profile = latestAssessment?.abstractedProfile {
            selectedTips = HealthTips.forProfile(profile)
        } else {
            selectedTips = Array(HealthTips.all.prefix(3))
        }
    }

    func refreshHealthKit() async {
        guard let healthDataProvider else { return }
        do {
            try await healthDataProvider.requestAuthorization()
            healthSnapshot = try await healthDataProvider.fetchWeeklySnapshot()
        } catch {
            healthSnapshot = .empty
        }
    }

    func toggleTipCompletion(_ tipID: String) {
        if completedTipIDs.contains(tipID) {
            completedTipIDs.remove(tipID)
        } else {
            completedTipIDs.insert(tipID)
        }
    }

    func runAssessment(
        profile: UserProfile?,
        orchestrator: AssessmentOrchestrator,
        modelContext: ModelContext
    ) async {
        guard let profile else {
            errorMessage = "Complete onboarding first."
            return
        }

        guard profile.phq9Score > 0 || profile.gad7Score > 0 else {
            errorMessage = "Complete questionnaires in the Assess tab first."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await orchestrator.requestHealthAuthorization()
            let result = try await orchestrator.runAssessment(profile: profile, modelContext: modelContext)
            latestAssessment = result.assessment
            latestSummary = result.summary
            selectedTips = HealthTips.forProfile(result.assessment.abstractedProfile)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
