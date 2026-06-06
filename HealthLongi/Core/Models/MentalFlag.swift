import Foundation

enum MentalFlag: String, Codable, CaseIterable, Sendable {
    case none
    case mild
    case moderateDepression = "moderate_depression"
    case severeDepression = "severe_depression"
    case moderateAnxiety = "moderate_anxiety"
    case highAnxiety = "high_anxiety"

    var displayName: String {
        switch self {
        case .none: "No concerns"
        case .mild: "Mild"
        case .moderateDepression: "Moderate depression"
        case .severeDepression: "Severe depression"
        case .moderateAnxiety: "Moderate anxiety"
        case .highAnxiety: "High anxiety"
        }
    }
}
