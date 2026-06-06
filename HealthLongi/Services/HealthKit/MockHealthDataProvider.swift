import Foundation

struct MockHealthDataProvider: HealthDataProviding {
    var snapshot: WeeklyHealthSnapshot
    var isHealthDataAvailable: Bool = false

    init(snapshot: WeeklyHealthSnapshot = WeeklyHealthSnapshot(
        averageDailySteps: 4200,
        hasStepData: true,
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

    func fetchDailySeries(for metric: HealthKitMetric, days: Int) async throws -> [DailyDataPoint] {
        MockHealthDataProvider.generateSeries(for: metric, days: days, base: snapshot)
    }

    static func generateSeries(for metric: HealthKitMetric, days: Int, base: WeeklyHealthSnapshot) -> [DailyDataPoint] {
        let calendar = Calendar.current
        let baseValue: Double = {
            switch metric {
            case .steps: Double(base.averageDailySteps)
            case .restingHeartRate: base.averageRestingHeartRate ?? 70
            case .sleep: base.averageSleepHours ?? 7
            case .activeEnergy: base.activeEnergyBurned ?? 300
            case .distance: base.distanceWalkingRunning ?? 3
            case .hrv: base.heartRateVariability ?? 40
            case .oxygenSaturation: base.oxygenSaturation ?? 97
            case .bodyMass: base.bodyMass ?? 75
            case .height: (base.height ?? 1.75) * 100
            case .bodyFat: base.bodyFatPercentage ?? 22
            case .mindfulMinutes: base.mindfulMinutes ?? 5
            }
        }()

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) else { return nil }
            let noise = sin(Double(offset) * 0.4) * baseValue * 0.08
            return DailyDataPoint(date: date, value: max(0, baseValue + noise))
        }.reversed()
    }
}
