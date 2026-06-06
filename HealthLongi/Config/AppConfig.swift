import Foundation

enum AppConfig {
    static var glmAPIKey: String? {
        validatedKey(Bundle.main.object(forInfoDictionaryKey: "GLM_API_KEY") as? String)
            ?? validatedKey(ProcessInfo.processInfo.environment["GLM_API_KEY"])
    }

    private static func validatedKey(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        guard key != "your_key_here", key != "api_key" else { return nil }
        guard !key.hasPrefix("$(") else { return nil }
        return key
    }
}
