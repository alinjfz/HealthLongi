import Foundation

struct LabFlag: Codable, Sendable, Equatable, Identifiable {
    enum Direction: String, Codable, Sendable {
        case above
        case below
    }

    var biomarker: LabBiomarker
    var value: Double
    var reference: LabReferenceRange
    var direction: Direction
    var flaggedAt: Date

    var id: String { biomarker.rawValue }

    var displaySummary: String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        let directionText = direction == .above ? "above" : "below"
        return "\(biomarker.label): \(formatted) \(reference.unit) (\(directionText) NHS range)"
    }
}
