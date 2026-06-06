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
    var lastRefreshedAt: Date?

    /// Tracks which data sources have new data since the last assessment
    var hasNewHealthData = false
    var hasNewQuestionnaireData = false

    private let healthDataProvider: (any HealthDataProviding)?
    private var lastAssessmentTimestamp: Date?

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
        lastAssessmentTimestamp = latestAssessment?.timestamp
    }

    func refreshHealthKit() async {
        guard let healthDataProvider else { return }
        do {
            try await healthDataProvider.requestAuthorization()
            let snapshot = try await healthDataProvider.fetchWeeklySnapshot()
            healthSnapshot = snapshot
            lastRefreshedAt = .now

            // Check if there's new data since last assessment
            if let lastAssessment = lastAssessmentTimestamp {
                hasNewHealthData = snapshot.fetchedAt > lastAssessment
            }
        } catch {
            healthSnapshot = .empty
        }
    }

    func markQuestionnaireDataUpdated() {
        hasNewQuestionnaireData = true
    }

    func toggleTipCompletion(_ tipID: String) {
        if completedTipIDs.contains(tipID) {
            completedTipIDs.remove(tipID)
        } else {
            completedTipIDs.insert(tipID)
        }
    }

    /// How many of the key data sources are completed
    func readinessProgress(for profile: UserProfile?) -> (completed: Int, total: Int, items: [ReadinessItem]) {
        var items: [ReadinessItem] = []
        var completed = 0

        // PHQ-9
        let phq9Done = (profile?.phq9Score ?? 0) > 0
        items.append(ReadinessItem(title: "PHQ-9 Questionnaire", icon: "brain.head.profile", isComplete: phq9Done))
        if phq9Done { completed += 1 }

        // GAD-7
        let gad7Done = (profile?.gad7Score ?? 0) > 0
        items.append(ReadinessItem(title: "GAD-7 Questionnaire", icon: "waveform.path.ecg", isComplete: gad7Done))
        if gad7Done { completed += 1 }

        // HealthKit data
        let hkDone = healthSnapshot != nil && healthSnapshot?.averageDailySteps ?? 0 > 0
        items.append(ReadinessItem(title: "HealthKit Data", icon: "heart.text.square.fill", isComplete: hkDone))
        if hkDone { completed += 1 }

        // Demographics
        let demoDone = profile != nil && profile!.onboardingComplete
        items.append(ReadinessItem(title: "Demographics", icon: "person.fill", isComplete: demoDone))
        if demoDone { completed += 1 }

        return (completed, items.count, items)
    }

    var canRunAssessment: Bool {
        guard let assessment = latestAssessment else { return true }
        return hasNewHealthData || hasNewQuestionnaireData || assessment.timestamp < Date.now.addingTimeInterval(-3600)
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
            hasNewHealthData = false
            hasNewQuestionnaireData = false
            lastAssessmentTimestamp = result.assessment.timestamp
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct ReadinessItem {
    let title: String
    let icon: String
    let isComplete: Bool
}
