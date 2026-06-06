import Foundation

enum HealthKitMetricAvailability: Equatable {
    case available
    case noData
    case unavailable

    var isInteractive: Bool {
        self == .available
    }

    var tooltipMessage: String {
        switch self {
        case .available:
            ""
        case .noData:
            "No data to show. Enable access in Settings → Health → Data Access, or add data in the Health app."
        case .unavailable:
            "HealthKit is not available on this device."
        }
    }

    var displayValue: String {
        switch self {
        case .available: ""
        case .noData, .unavailable: "—"
        }
    }

    static func availability(
        for metric: HealthKitMetric,
        snapshot: WeeklyHealthSnapshot,
        isHealthDataAvailable: Bool
    ) -> HealthKitMetricAvailability {
        guard isHealthDataAvailable else { return .unavailable }

        let hasValue: Bool = switch metric {
        case .steps:
            snapshot.hasStepData
        case .restingHeartRate:
            snapshot.averageRestingHeartRate != nil
        case .sleep:
            snapshot.averageSleepHours != nil
        case .activeEnergy:
            snapshot.activeEnergyBurned != nil
        case .distance:
            snapshot.distanceWalkingRunning != nil
        case .hrv:
            snapshot.heartRateVariability != nil
        case .oxygenSaturation:
            snapshot.oxygenSaturation != nil
        case .bodyMass:
            snapshot.bodyMass != nil
        case .height:
            snapshot.height != nil
        case .bodyFat:
            snapshot.bodyFatPercentage != nil
        case .mindfulMinutes:
            snapshot.mindfulMinutes != nil
        }

        return hasValue ? .available : .noData
    }
}
