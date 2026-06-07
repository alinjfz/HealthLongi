import Foundation

/// OpenAI-compatible chat completion client used by GLM, OpenRouter, and similar providers.
struct ChatCompletionAIService: AISummarizing {
    struct Configuration: Sendable {
        let endpoint: URL
        let model: String
        let apiKey: String?
        let disableGLMThinking: Bool
        let referer: String?
        let appTitle: String?
        let providerOnly: [String]?
        let allowFallbacks: Bool?

        static func glm(apiKey: String? = AppConfig.glmAPIKey) -> Configuration {
            Configuration(
                endpoint: URL(string: "https://api.z.ai/api/paas/v4/chat/completions")!,
                model: "glm-4.5-air",
                apiKey: apiKey,
                disableGLMThinking: true,
                referer: nil,
                appTitle: nil,
                providerOnly: nil,
                allowFallbacks: nil
            )
        }

        static func openRouter(
            apiKey: String? = AppConfig.openRouterAPIKey,
            model: String = AppConfig.openRouterModel
        ) -> Configuration {
            Configuration(
                endpoint: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
                model: model,
                apiKey: apiKey,
                disableGLMThinking: false,
                referer: AppConfig.openRouterReferer,
                appTitle: AppConfig.openRouterAppTitle,
                providerOnly: AppConfig.openRouterProviderOnly,
                allowFallbacks: AppConfig.openRouterAllowFallbacks
            )
        }
    }

    private let configuration: Configuration
    private let session: URLSession

    init(configuration: Configuration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    #if DEBUG
    var debugConfiguration: Configuration { configuration }
    #endif

    func summarize(context: AIHealthContext) async throws -> AISummaryResult {
        guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
            AIDebugLogger.logFallback(reason: "API key missing or still a placeholder in Secrets.xcconfig")
            return NHSGroundedFallback.make(context: context)
        }

        let allowedIDs = Set(context.nhsTopics.map(\.id))

        for attempt in 1...3 {
            do {
                let content = try await requestInsight(context: context, apiKey: apiKey, attempt: attempt)
                let raw = AIResponseParser.parse(content: content, allowedTopicIDs: allowedIDs)
                return AIResponseParser.makeResult(from: raw, context: context, usedFallback: false)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                AIDebugLogger.logError("Attempt \(attempt) failed", error: error)
                guard attempt == 3 else {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                    continue
                }
                AIDebugLogger.logFallback(reason: "all 3 attempts failed — \(error)")
                return NHSGroundedFallback.make(context: context)
            }
        }

        AIDebugLogger.logFallback(reason: "exhausted retries")
        return NHSGroundedFallback.make(context: context)
    }

    private func requestInsight(context: AIHealthContext, apiKey: String, attempt: Int) async throws -> String {
        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US,en", forHTTPHeaderField: "Accept-Language")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        if let referer = configuration.referer {
            request.setValue(referer, forHTTPHeaderField: "HTTP-Referer")
        }
        if let appTitle = configuration.appTitle {
            request.setValue(appTitle, forHTTPHeaderField: "X-Title")
        }

        let userPrompt = AISummaryPrompts.userPrompt(for: context)
        var body: [String: Any] = [
            "model": configuration.model,
            "messages": [
                ["role": "system", "content": AISummaryPrompts.systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.4,
            "max_tokens": 1000
        ]

        if configuration.disableGLMThinking {
            body["thinking"] = ["type": "disabled"]
        }

        if configuration.providerOnly != nil || configuration.allowFallbacks != nil {
            var provider: [String: Any] = [:]
            if let providerOnly = configuration.providerOnly, !providerOnly.isEmpty {
                provider["only"] = providerOnly
            }
            if let allowFallbacks = configuration.allowFallbacks {
                provider["allow_fallbacks"] = allowFallbacks
            }
            body["provider"] = provider
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        AIDebugLogger.logRequest(
            attempt: attempt,
            model: configuration.model,
            endpoint: configuration.endpoint,
            promptLength: userPrompt.count
        )

        let started = ContinuousClock.now
        let (data, response) = try await session.data(for: request)
        let elapsed = started.duration(to: .now)
        let durationMs = Int(elapsed.components.seconds * 1000
            + elapsed.components.attoseconds / 1_000_000_000_000_000)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        AIDebugLogger.logResponse(statusCode: statusCode, body: data, durationMs: max(durationMs, 0))
        if statusCode == 402 {
            AIDebugLogger.logHTTP402Hint()
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw ChatCompletionError.requestFailed(statusCode: statusCode == -1 ? nil : statusCode, body: bodyText)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        if let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
           !content.isEmpty {
            AIDebugLogger.logSuccess(contentLength: content.count)
            return content
        }
        throw ChatCompletionError.emptyResponse
    }
}

enum ChatCompletionError: Error, CustomStringConvertible {
    case requestFailed(statusCode: Int?, body: String)
    case emptyResponse

    var description: String {
        switch self {
        case .requestFailed(let statusCode, let body):
            let preview = body.count > 200 ? String(body.prefix(200)) + "…" : body
            return "HTTP \(statusCode ?? -1) — \(preview)"
        case .emptyResponse:
            return "Empty model response"
        }
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [ChatCompletionChoice]
}

private struct ChatCompletionChoice: Decodable {
    let message: ChatCompletionMessage
}

private struct ChatCompletionMessage: Decodable {
    let content: String?
}
