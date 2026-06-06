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
    var hasNewLabData = false

    private let healthDataProvider: (any HealthDataProviding)?
    private var lastAssessmentTimestamp: Date?
    private var isRunningAssessment = false

    init(healthDataProvider: (any HealthDataProviding)? = nil) {
        self.healthDataProvider = healthDataProvider
    }

    func loadLatest(from assessments: [RiskAssessment], preferExistingSummary: Bool = false) {
        let sorted = assessments.sorted { $0.timestamp > $1.timestamp }
        latestAssessment = sorted.first

        if let assessment = latestAssessment {
            let summarySource = sorted.first(where: { !$0.usedAIFallback }) ?? assessment
            let loadedSummary = AISummaryResult(
                markdownSummary: summarySource.aiSummaryText,
                suggestedLinkKeys: NHSLinks.links(for: summarySource.abstractedProfile).map(\.id),
                usedFallback: summarySource.usedAIFallback
            )

            if preferExistingSummary,
               let latestSummary,
               !latestSummary.usedFallback,
               loadedSummary.usedFallback {
                // Keep in-memory AI summary if DB row is a fallback from a failed refresh.
            } else {
                latestSummary = loadedSummary
            }

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

    func markLabDataUpdated() {
        hasNewLabData = true
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

        // Lab results
        let labsDone = profile?.labResults?.hasAnyValue == true
        items.append(ReadinessItem(title: "Lab Results", icon: "flask.fill", isComplete: labsDone))
        if labsDone { completed += 1 }

        return (completed, items.count, items)
    }

    func autoRunAssessmentIfNeeded(
        profile: UserProfile?,
        orchestrator: AssessmentOrchestrator,
        modelContext: ModelContext,
        reason: AutoAssessmentReason,
        showsProgress: Bool = true
    ) async {
        guard !isRunningAssessment else { return }
        guard let profile else { return }
        guard profile.phq9Score > 0 || profile.gad7Score > 0 else { return }

        let shouldRun: Bool = switch reason {
        case .appOpened, .userRefresh:
            true
        case .newData:
            hasNewHealthData || hasNewQuestionnaireData || hasNewLabData
        }

        guard shouldRun else { return }

        isRunningAssessment = true
        if showsProgress { isUpdatingAssessment = true }
        defer {
            isRunningAssessment = false
            if showsProgress { isUpdatingAssessment = false }
        }

        errorMessage = nil
        let previousSummary = latestSummary

        do {
            try await orchestrator.requestHealthAuthorization()
            let result = try await orchestrator.runAssessment(profile: profile, modelContext: modelContext)
            latestAssessment = result.assessment
            latestSummary = resolvedSummary(
                result: result,
                previous: previousSummary,
                reason: reason
            )
            selectedTips = HealthTips.forProfile(result.assessment.abstractedProfile)
            hasNewHealthData = false
            hasNewQuestionnaireData = false
            hasNewLabData = false
            lastAssessmentTimestamp = result.assessment.timestamp
            lastRefreshedAt = .now
        } catch is CancellationError {
            // Keep the existing summary when refresh is cancelled.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolvedSummary(
        result: AssessmentOrchestrator.AssessmentRunResult,
        previous: AISummaryResult?,
        reason: AutoAssessmentReason
    ) -> AISummaryResult {
        guard result.summary.usedFallback,
              reason == .userRefresh,
              let previous,
              !previous.usedFallback else {
            return result.summary
        }

        return AISummaryResult(
            markdownSummary: previous.markdownSummary,
            suggestedLinkKeys: NHSLinks.links(for: result.assessment.abstractedProfile).map(\.id),
            usedFallback: false
        )
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
