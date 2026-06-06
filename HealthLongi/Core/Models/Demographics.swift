import Foundation

enum Sex: String, Codable, CaseIterable, Sendable {
    case male
    case female
    case other

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        }
    }
}

enum SmokingStatus: String, Codable, CaseIterable, Sendable {
    case never
    case former
    case current

    var displayName: String {
        switch self {
        case .never: "Never smoked"
        case .former: "Former smoker"
        case .current: "Current smoker"
        }
    }
}

struct Demographics: Codable, Sendable, Equatable {
    var age: Int
    var sex: Sex
    var smokingStatus: SmokingStatus
}
