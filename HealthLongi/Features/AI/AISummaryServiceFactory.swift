import Foundation

/// Creates the active AI summarizer. Switch providers in `AppConfig.aiProvider`.
enum AISummaryServiceFactory {
    static func make(session: URLSession = .shared) -> any AISummarizing {
        let service: ChatCompletionAIService = switch AppConfig.aiProvider {
        case .glm:
            ChatCompletionAIService(configuration: .glm(), session: session)
        case .openRouter:
            ChatCompletionAIService(configuration: .openRouter(), session: session)
        }

        #if DEBUG
        AIDebugLogger.logProviderStartup(provider: AppConfig.aiProvider, configuration: service.debugConfiguration)
        #endif

        return service
    }
}
