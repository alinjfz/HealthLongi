import Foundation

struct MockHealthDataProvider: HealthDataProviding {
    var snapshot: WeeklyHealthSnapshot

    init(snapshot: WeeklyHealthSnapshot = WeeklyHealthSnapshot(
        averageDailySteps: 4200,
        priorAverageDailySteps: 6800,
        averageRestingHeartRate: 78,
        averageSleepHours: 5.5,
        fetchedAt: .now
    )) {
        self.snapshot = snapshot
    }

    func requestAuthorization() async throws {}

    func fetchWeeklySnapshot() async throws -> WeeklyHealthSnapshot {
        snapshot
    }
}
