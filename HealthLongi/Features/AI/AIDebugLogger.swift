import Foundation

enum AIDebugLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("[AI] \(message)")
        #endif
    }

    static func logProviderStartup(provider: AIProvider, configuration: ChatCompletionAIService.Configuration) {
        #if DEBUG
        log("Active provider: \(provider.rawValue)")
        log("Endpoint: \(configuration.endpoint.absoluteString)")
        log("Model: \(configuration.model)")
        log("API key: \(maskedKey(configuration.apiKey))")
        if configuration.apiKey == nil {
            log("No API key loaded — check Secrets.xcconfig / Info.plist / Xcode scheme environment variables.")
        }
        if let referer = configuration.referer {
            log("HTTP-Referer: \(referer)")
        }
        if let appTitle = configuration.appTitle {
            log("X-Title: \(appTitle)")
        }
        if let providerOnly = configuration.providerOnly, !providerOnly.isEmpty {
            log("Provider only: \(providerOnly.joined(separator: ", "))")
        }
        if let allowFallbacks = configuration.allowFallbacks {
            log("Allow OpenRouter fallbacks: \(allowFallbacks)")
        }
        #endif
    }

    static func logHTTP402Hint() {
        #if DEBUG
        log("""
        HTTP 402 usually means OpenRouter tried its own paid pool (no credits on account).
        With BYOK: ensure your provider key matches the model (e.g. amazon-bedrock for anthropic/claude-*),
        enable "Always use for this provider" in OpenRouter BYOK settings, or add credits at
        https://openrouter.ai/settings/credits — or switch AppConfig.aiProvider to .glm for direct API.
        """)
        #endif
    }

    static func maskedKey(_ key: String?) -> String {
        guard let key, !key.isEmpty else { return "<missing>" }
        if key.count <= 8 { return "<set, length \(key.count)>" }
        return "\(key.prefix(6))...\(key.suffix(4)) (length \(key.count))"
    }

    static func logRequest(attempt: Int, model: String, endpoint: URL, promptLength: Int) {
        #if DEBUG
        log("Request attempt \(attempt) → \(endpoint.host ?? endpoint.absoluteString) model=\(model) promptChars=\(promptLength)")
        #endif
    }

    static func logResponse(statusCode: Int, body: Data, durationMs: Int) {
        #if DEBUG
        let text = String(data: body, encoding: .utf8) ?? "<non-utf8 body, \(body.count) bytes>"
        let preview = text.count > 800 ? String(text.prefix(800)) + "…" : text
        log("Response HTTP \(statusCode) in \(durationMs)ms")
        log("Body: \(preview)")
        #endif
    }

    static func logSuccess(contentLength: Int) {
        #if DEBUG
        log("Summary received (\(contentLength) chars)")
        #endif
    }

    static func logFallback(reason: String) {
        #if DEBUG
        log("Using offline fallback — \(reason)")
        #endif
    }

    static func logError(_ message: String, error: Error? = nil) {
        #if DEBUG
        if let error {
            log("\(message): \(error)")
        } else {
            log(message)
        }
        #endif
    }
}
