import Foundation

enum RiskLevel: String, Codable, CaseIterable, Sendable {
    case low
    case moderate
    case high

    var displayName: String {
        switch self {
        case .low: "Low"
        case .moderate: "Moderate"
        case .high: "High"
        }
    }

    var description: String {
        switch self {
        case .low:
            "Your current indicators suggest a lower level of risk in this area. Keep maintaining healthy habits."
        case .moderate:
            "Some factors suggest moderate risk. Lifestyle changes and regular check-ups may help."
        case .high:
            "Several factors indicate elevated risk. Consider speaking with your GP for personalised advice."
        }
    }
}
