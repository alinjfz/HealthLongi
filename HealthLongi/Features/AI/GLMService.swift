import Foundation

struct GLMService: AISummarizing {
    private let apiKey: String?
    private let session: URLSession
    private let endpoint = URL(string: "https://api.z.ai/api/paas/v4/chat/completions")!
    private let model = "glm-4.5-air"

    init(apiKey: String? = AppConfig.glmAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func summarize(profile: AbstractedRiskProfile) async throws -> AISummaryResult {
        guard let apiKey, !apiKey.isEmpty else {
            return fallbackResult(for: profile)
        }

        for attempt in 1...3 {
            do {
                let markdown = try await requestSummary(profile: profile, apiKey: apiKey)
                return AISummaryResult(
                    markdownSummary: markdown,
                    suggestedLinkKeys: NHSLinks.links(for: profile).map(\.id),
                    usedFallback: false
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard attempt == 3 else {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                    continue
                }
                return fallbackResult(for: profile)
            }
        }

        return fallbackResult(for: profile)
    }

    private func requestSummary(profile: AbstractedRiskProfile, apiKey: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US,en", forHTTPHeaderField: "Accept-Language")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": GLMPrompts.systemPrompt],
                ["role": "user", "content": GLMPrompts.userPrompt(for: profile)]
            ],
            "temperature": 0.75,
            "max_tokens": 180,
            "thinking": ["type": "disabled"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GLMError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode)
        }

        let decoded = try JSONDecoder().decode(GLMChatResponse.self, from: data)
        if let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
           !content.isEmpty {
            return content
        }
        throw GLMError.emptyResponse
    }

    private func fallbackResult(for profile: AbstractedRiskProfile) -> AISummaryResult {
        AISummaryResult(
            markdownSummary: GLMPrompts.fallbackText(for: profile),
            suggestedLinkKeys: NHSLinks.links(for: profile).map(\.id),
            usedFallback: true
        )
    }
}

enum GLMError: Error {
    case requestFailed(statusCode: Int?)
    case emptyResponse
}

private struct GLMChatResponse: Decodable {
    let choices: [GLMChoice]
}

private struct GLMChoice: Decodable {
    let message: GLMMessage
}

private struct GLMMessage: Decodable {
    let content: String?
}
