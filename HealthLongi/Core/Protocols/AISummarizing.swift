import Foundation

protocol AISummarizing: Sendable {
    func summarize(context: AIHealthContext) async throws -> AISummaryResult
}
