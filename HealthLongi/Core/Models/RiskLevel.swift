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
}
