import Foundation

struct WeeklyHealthSnapshot: Sendable, Equatable {
    // Activity
    var averageDailySteps: Int
    var hasStepData: Bool = false
    var priorAverageDailySteps: Int?
    var activeEnergyBurned: Double?       // kcal/day average
    var distanceWalkingRunning: Double?   // km/day average

    // Vitals
    var averageRestingHeartRate: Double?  // bpm
    var heartRateVariability: Double?     // SDNN in ms
    var oxygenSaturation: Double?         // %

    // Sleep
    var averageSleepHours: Double?

    // Body
    var bodyMass: Double?                 // kg
    var height: Double?                   // metres
    var bodyFatPercentage: Double?        // %

    // Mindfulness
    var mindfulMinutes: Double?           // min/day average

    // Metadata
    var fetchedAt: Date

    /// Computed BMI from body mass and height
    var bmi: Double? {
        guard let mass = bodyMass, let h = height, h > 0 else { return nil }
        let bmiValue = mass / (h * h)
        return bmiValue.isFinite ? bmiValue : nil
    }

    static let empty = WeeklyHealthSnapshot(
        averageDailySteps: 0,
        hasStepData: false,
        priorAverageDailySteps: nil,
        activeEnergyBurned: nil,
        distanceWalkingRunning: nil,
        averageRestingHeartRate: nil,
        heartRateVariability: nil,
        oxygenSaturation: nil,
        averageSleepHours: nil,
        bodyMass: nil,
        height: nil,
        bodyFatPercentage: nil,
        mindfulMinutes: nil,
        fetchedAt: .now
    )
}
