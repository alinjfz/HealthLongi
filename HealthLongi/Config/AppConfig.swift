import Foundation

enum AppConfig {
    static var glmAPIKey: String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GLM_API_KEY") as? String,
           !key.isEmpty,
           key != "your_key_here" {
            return key
        }
        return ProcessInfo.processInfo.environment["GLM_API_KEY"]
    }
}
