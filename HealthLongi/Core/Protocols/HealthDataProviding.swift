import Foundation

protocol HealthDataProviding: Sendable {
    func requestAuthorization() async throws
    func fetchWeeklySnapshot() async throws -> WeeklyHealthSnapshot
}
