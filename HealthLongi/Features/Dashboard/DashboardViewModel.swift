import Foundation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
    var isLoading = false
    var errorMessage: String?
    var latestAssessment: RiskAssessment?
    var latestSummary: AISummaryResult?

    func loadLatest(from assessments: [RiskAssessment]) {
        latestAssessment = assessments.sorted { $0.timestamp > $1.timestamp }.first
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
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
