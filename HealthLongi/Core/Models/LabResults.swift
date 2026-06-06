import Foundation

struct LabResults: Codable, Sendable, Equatable {
    var cholesterol: Double?
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var bloodSugar: Double?
    var hba1c: Double?
    var lastUpdated: Date

    static let empty = LabResults(lastUpdated: .now)
}
