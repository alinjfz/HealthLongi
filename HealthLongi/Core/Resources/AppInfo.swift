import Foundation

struct AppInfo {
    static let appName = "Vitals & Mind"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let developerName = "HealthLongi Team"
    static let supportEmail = "support@healthlongi.app"
    static let websiteURL = URL(string: "https://healthlongi.app")!
    static let privacyPolicyURL = URL(string: "https://healthlongi.app/privacy")!
    static let termsOfServiceURL = URL(string: "https://healthlongi.app/terms")!

    static let disclaimer = """
    This app is for informational purposes only and does not replace professional medical advice.
    Health data is processed on-device. Only anonymized risk profiles are sent to AI services.
    """
}
