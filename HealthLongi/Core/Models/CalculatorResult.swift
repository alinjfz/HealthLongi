import SwiftUI

struct BMICalculatorResult {
    let bmi: Double
    let weight: Double
    let height: Double

    var category: BMICategory {
        switch bmi {
        case 0..<18.5: .underweight
        case 18.5..<24.9: .normal
        case 25..<29.9: .overweight
        default: .obese
        }
    }

    static func calculate(weightKg: Double, heightCm: Double) -> BMICalculatorResult? {
        guard weightKg > 0, heightCm > 0 else { return nil }
        let heightM = heightCm / 100
        let bmi = weightKg / (heightM * heightM)
        guard bmi.isFinite, bmi > 0 else { return nil }
        return BMICalculatorResult(bmi: bmi, weight: weightKg, height: heightCm)
    }
}

enum BMICategory {
    case underweight, normal, overweight, obese

    static func from(bmi: Double) -> BMICategory {
        switch bmi {
        case 0..<18.5: .underweight
        case 18.5..<25: .normal
        case 25..<30: .overweight
        default: .obese
        }
    }

    var displayName: String {
        switch self {
        case .underweight: "Underweight"
        case .normal: "Normal weight"
        case .overweight: "Overweight"
        case .obese: "Obese"
        }
    }

    var color: Color {
        switch self {
        case .underweight: NHSTheme.primaryBlue
        case .normal: .green
        case .overweight: .orange
        case .obese: .red
        }
    }
}
