import Foundation

protocol HealthDataProviding: Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func fetchWeeklySnapshot() async throws -> WeeklyHealthSnapshot
    func fetchProfileDemographics() async -> ProfileDemographicsSnapshot
    func fetchDailySeries(for metric: HealthKitMetric, days: Int) async throws -> [DailyDataPoint]
}

extension HealthDataProviding {
    var isHealthDataAvailable: Bool { true }

    func fetchProfileDemographics() async -> ProfileDemographicsSnapshot {
        ProfileDemographicsSnapshot()
    }

    func fetchDailySeries(for metric: HealthKitMetric, days: Int) async throws -> [DailyDataPoint] {
        []
    }
}
