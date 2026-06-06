import Foundation

/// User-entered values used when HealthKit does not provide a metric.
struct ManualHealthData: Codable, Sendable, Equatable {
    var dateOfBirth: Date?
    var sexRaw: String?

    var averageDailySteps: Int?
    var distanceWalkingRunningKm: Double?
    var activeEnergyBurnedKcal: Double?
    var mindfulMinutesPerDay: Double?
    var physicalActivityMinutesPerWeek: Int?

    var restingHeartRateBPM: Double?
    var heartRateVariabilityMS: Double?
    var oxygenSaturationPercent: Double?

    var bodyMassKg: Double?
    var heightMeters: Double?
    var bodyFatPercentage: Double?
    var bmi: Double?

    var averageSleepHours: Double?

    var lastUpdated: Date?

    static let empty = ManualHealthData(lastUpdated: nil)
}

struct ProfileDemographicsSnapshot: Sendable, Equatable {
    var dateOfBirth: Date?
    var biologicalSex: Sex?
}

enum HealthMetricSource: String, Sendable {
    case healthKit
    case manual
    case unavailable

    var label: String {
        switch self {
        case .healthKit: "Apple Health"
        case .manual: "Added by you"
        case .unavailable: "Not set"
        }
    }

    var icon: String {
        switch self {
        case .healthKit: "heart.text.square.fill"
        case .manual: "square.and.pencil"
        case .unavailable: "minus.circle"
        }
    }
}

enum ProfileHealthMetricKey: String, CaseIterable, Identifiable {
    case dateOfBirth
    case sex
    case genderIdentity
    case smoking

    case dailySteps
    case walkingDistance
    case activeEnergy
    case mindfulMinutes
    case physicalActivity

    case restingHeartRate
    case heartRateVariability
    case oxygenSaturation

    case bodyMass
    case height
    case bmi
    case bodyFat

    case sleep

    var id: String { rawValue }
}

struct ProfileHealthMetric: Identifiable, Sendable {
    let key: ProfileHealthMetricKey
    let title: String
    let value: String
    let detail: String?
    let icon: String
    let source: HealthMetricSource
    let allowsManualEntry: Bool

    var id: String { key.rawValue }
}

struct ProfileHealthGroup: Identifiable, Sendable {
    let title: String
    let icon: String
    let metrics: [ProfileHealthMetric]

    var id: String { title }
}
