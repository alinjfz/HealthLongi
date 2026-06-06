import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }

    var label: String {
        switch self {
        case .kg: "kg"
        case .lb: "lb"
        }
    }

    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: value
        case .lb: value * 0.453592
        }
    }

    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .kg: kg
        case .lb: kg / 0.453592
        }
    }
}

enum HeightUnit: String, CaseIterable, Identifiable {
    case cm
    case ftIn

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cm: "cm"
        case .ftIn: "ft / in"
        }
    }

    static func toCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * 2.54
    }

    static func fromCm(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = Int(round(cm / 2.54))
        return (totalInches / 12, totalInches % 12)
    }
}
