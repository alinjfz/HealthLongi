import Foundation

enum Sex: String, Codable, CaseIterable, Sendable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }
}

enum SmokingStatus: String, Codable, CaseIterable, Sendable {
    case never
    case former
    case currentRegular
    case currentOccasional
    case vapingRegular
    case vapingOccasional

    var displayName: String {
        switch self {
        case .never: "Never smoked"
        case .former: "Former smoker"
        case .currentRegular: "Current smoker (daily)"
        case .currentOccasional: "Current smoker (occasionally)"
        case .vapingRegular: "Vaping (daily)"
        case .vapingOccasional: "Vaping (occasionally)"
        }
    }

    var hasFrequency: Bool {
        self == .currentOccasional || self == .vapingOccasional
    }

    /// Maps legacy `current` raw value from earlier app versions.
    static func fromStored(_ raw: String) -> SmokingStatus {
        if raw == "current" { return .currentRegular }
        return SmokingStatus(rawValue: raw) ?? .never
    }

    var isActiveSmoker: Bool {
        switch self {
        case .currentRegular, .currentOccasional, .vapingRegular, .vapingOccasional:
            true
        case .never, .former:
            false
        }
    }
}

struct Demographics: Codable, Sendable, Equatable {
    var age: Int
    var sex: Sex
    var smokingStatus: SmokingStatus
    var smokingFrequency: String?
    var genderIdentity: String?
}
