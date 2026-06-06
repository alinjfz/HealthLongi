import Foundation

protocol AISummarizing: Sendable {
    func summarize(profile: AbstractedRiskProfile) async throws -> AISummaryResult
}
