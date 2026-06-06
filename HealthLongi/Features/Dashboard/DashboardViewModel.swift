import Foundation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
    var isUpdatingAssessment = false
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
    private var isRunningAssessment = false

    init(healthDataProvider: (any HealthDataProviding)? = nil) {
        self.healthDataProvider = healthDataProvider
    }

    func loadLatest(from assessments: [RiskAssessment]) {
        latestAssessment = assessments.sorted { $0.timestamp > $1.timestamp }.first
        if let assessment = latestAssessment {
            latestSummary = AISummaryResult(
                markdownSummary: assessment.aiSummaryText,
                suggestedLinkKeys: NHSLinks.links(for: assessment.abstractedProfile).map(\.id),
                usedFallback: assessment.usedAIFallback
            )
            selectedTips = HealthTips.forProfile(assessment.abstractedProfile)
        } else {
            latestSummary = nil
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
            } else if snapshot.averageDailySteps > 0 {
                hasNewHealthData = true
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

    func autoRunAssessmentIfNeeded(
        profile: UserProfile?,
        orchestrator: AssessmentOrchestrator,
        modelContext: ModelContext,
        reason: AutoAssessmentReason
    ) async {
        guard !isRunningAssessment else { return }
        guard let profile else { return }
        guard profile.phq9Score > 0 || profile.gad7Score > 0 else { return }

        let shouldRun: Bool = switch reason {
        case .appOpened, .userRefresh:
            true
        case .newData:
            hasNewHealthData || hasNewQuestionnaireData
        }

        guard shouldRun else { return }

        isRunningAssessment = true
        defer { isRunningAssessment = false }

        isUpdatingAssessment = true
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

        isUpdatingAssessment = false
    }
}

enum AutoAssessmentReason {
    case appOpened
    case newData
    case userRefresh
}

struct ReadinessItem {
    let title: String
    let icon: String
    let isComplete: Bool
}
