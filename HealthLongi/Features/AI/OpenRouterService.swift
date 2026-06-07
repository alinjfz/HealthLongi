import Foundation

/// OpenRouter provider wrapper. Prefer `AISummaryServiceFactory.make()` for app wiring.
struct OpenRouterService: AISummarizing {
    private let service: ChatCompletionAIService

    init(
        apiKey: String? = AppConfig.openRouterAPIKey,
        model: String = AppConfig.openRouterModel,
        session: URLSession = .shared
    ) {
        service = ChatCompletionAIService(
            configuration: .openRouter(apiKey: apiKey, model: model),
            session: session
        )
    }

    func summarize(profile: AbstractedRiskProfile) async throws -> AISummaryResult {
        try await service.summarize(profile: profile)
    }
}
