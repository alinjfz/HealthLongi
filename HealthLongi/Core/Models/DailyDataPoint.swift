import Foundation

struct DailyDataPoint: Identifiable, Sendable, Equatable {
    let date: Date
    let value: Double

    var id: Date { date }
}

extension HealthKitMetric {
    var supportsTrendChart: Bool {
        switch self {
        case .steps, .restingHeartRate, .sleep, .activeEnergy, .distance, .hrv, .oxygenSaturation, .bodyMass, .mindfulMinutes:
            true
        case .height, .bodyFat, .bmi, .exerciseMinutes:
            false
        }
    }
}
