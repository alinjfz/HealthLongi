import Foundation

/// GLM provider wrapper. Prefer `AISummaryServiceFactory.make()` for app wiring.
struct GLMService: AISummarizing {
    private let service: ChatCompletionAIService

    init(apiKey: String? = AppConfig.glmAPIKey, session: URLSession = .shared) {
        service = ChatCompletionAIService(configuration: .glm(apiKey: apiKey), session: session)
    }

    func summarize(context: AIHealthContext) async throws -> AISummaryResult {
        try await service.summarize(context: context)
    }
}
