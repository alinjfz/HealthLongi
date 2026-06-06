import Foundation

struct GLMService: AISummarizing {
    private let apiKey: String?
    private let session: URLSession
    private let endpoint = URL(string: "https://api.z.ai/api/paas/v4/chat/completions")!

    init(apiKey: String? = AppConfig.glmAPIKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func summarize(profile: AbstractedRiskProfile) async throws -> AISummaryResult {
        guard let apiKey, !apiKey.isEmpty else {
            return fallbackResult(for: profile)
        }

        do {
            let markdown = try await requestSummary(profile: profile, apiKey: apiKey)
            return AISummaryResult(
                markdownSummary: markdown,
                suggestedLinkKeys: NHSLinks.links(for: profile).map(\.id),
                usedFallback: false
            )
        } catch {
            return fallbackResult(for: profile)
        }
    }

    private func requestSummary(profile: AbstractedRiskProfile, apiKey: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "glm-4-flash",
            "messages": [
                ["role": "system", "content": GLMPrompts.systemPrompt],
                ["role": "user", "content": GLMPrompts.userPrompt(for: profile)]
            ],
            "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GLMError.requestFailed
        }

        let decoded = try JSONDecoder().decode(GLMChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw GLMError.emptyResponse
        }
        return content
    }

    private func fallbackResult(for profile: AbstractedRiskProfile) -> AISummaryResult {
        var summary = AISummaryResult.fallback.markdownSummary

        if profile.correlations.contains("dropping_steps_with_high_gad7") {
            summary += """

            **Mind-body connection:** Your recent decrease in physical activity alongside elevated anxiety \
            is a pattern worth discussing with your GP. Small daily walks can help both body and mind.
            """
        }

        return AISummaryResult(
            markdownSummary: summary,
            suggestedLinkKeys: NHSLinks.links(for: profile).map(\.id),
            usedFallback: true
        )
    }
}

enum GLMError: Error {
    case requestFailed
    case emptyResponse
}

private struct GLMChatResponse: Decodable {
    let choices: [GLMChoice]
}

private struct GLMChoice: Decodable {
    let message: GLMMessage
}

private struct GLMMessage: Decodable {
    let content: String
}
