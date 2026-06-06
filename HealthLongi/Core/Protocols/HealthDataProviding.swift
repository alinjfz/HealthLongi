import Foundation

protocol HealthDataProviding: Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func fetchWeeklySnapshot() async throws -> WeeklyHealthSnapshot
    func fetchProfileDemographics() async -> ProfileDemographicsSnapshot
}

extension HealthDataProviding {
    var isHealthDataAvailable: Bool { true }

    func fetchProfileDemographics() async -> ProfileDemographicsSnapshot {
        ProfileDemographicsSnapshot()
    }
}
