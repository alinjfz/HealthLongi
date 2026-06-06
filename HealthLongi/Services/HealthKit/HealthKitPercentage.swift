import Foundation

/// Normalizes HealthKit fraction values (0.0–1.0) to display percentages (0–100).
enum HealthKitPercentage {
    static func displayPercent(from raw: Double?) -> Double? {
        guard let raw else { return nil }
        return raw <= 1.5 ? raw * 100 : raw
    }
}
