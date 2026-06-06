import Foundation

struct MockHealthDataProvider: HealthDataProviding {
    var snapshot: WeeklyHealthSnapshot
    var isHealthDataAvailable: Bool = false

    init(snapshot: WeeklyHealthSnapshot = WeeklyHealthSnapshot(
        averageDailySteps: 4200,
        priorAverageDailySteps: 6800,
        activeEnergyBurned: 320,
        distanceWalkingRunning: 3.2,
        averageRestingHeartRate: 78,
        heartRateVariability: 42,
        oxygenSaturation: 97,
        averageSleepHours: 5.5,
        bodyMass: 75,
        height: 1.75,
        bodyFatPercentage: 22,
        mindfulMinutes: 5,
        fetchedAt: .now
    )) {
        self.snapshot = snapshot
    }

    func requestAuthorization() async throws {}

    func fetchWeeklySnapshot() async throws -> WeeklyHealthSnapshot {
        snapshot
    }
}
