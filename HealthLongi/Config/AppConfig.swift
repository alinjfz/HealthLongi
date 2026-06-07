import Foundation

/// Switch AI providers here. Change `.openRouter` back to `.glm` anytime.
enum AIProvider: String, Sendable {
    case glm
    case openRouter
}

enum AppConfig {
    static let aiProvider: AIProvider = .openRouter

    /// OpenRouter model slug — must be available on your BYOK provider.
    /// Cheapest Bedrock option: Nova Micro (~$0.035/M in, $0.14/M out). Enable in AWS Bedrock console.
    static let openRouterModel = "amazon/nova-micro-v1"

    /// Pin routing to your BYOK provider. Use `["amazon-bedrock"]` when BYOK is AWS Bedrock.
    /// Prevents fallback to OpenRouter's paid pool when you have no credits.
    static let openRouterProviderOnly: [String]? = ["amazon-bedrock"]

    /// When false, OpenRouter won't fall back to its own credits if BYOK fails.
    static let openRouterAllowFallbacks = false

    static let openRouterReferer = "https://github.com/pahlavan/HealthLongi"
    static let openRouterAppTitle = "Vitals & Mind"

    static var glmAPIKey: String? {
        validatedKey(Bundle.main.object(forInfoDictionaryKey: "GLM_API_KEY") as? String)
            ?? validatedKey(ProcessInfo.processInfo.environment["GLM_API_KEY"])
    }

    static var openRouterAPIKey: String? {
        validatedKey(Bundle.main.object(forInfoDictionaryKey: "OPENROUTER_API_KEY") as? String)
            ?? validatedKey(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"])
    }

    private static func validatedKey(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        guard key != "your_key_here", key != "api_key" else { return nil }
        guard key != "your_openrouter_key_here" else { return nil }
        guard !key.hasPrefix("$(") else { return nil }
        return key
    }
}
