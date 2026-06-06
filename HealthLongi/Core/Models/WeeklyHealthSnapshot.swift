import Foundation

struct WeeklyHealthSnapshot: Sendable, Equatable {
    var averageDailySteps: Int
    var priorAverageDailySteps: Int?
    var averageRestingHeartRate: Double?
    var averageSleepHours: Double?
    var fetchedAt: Date

    static let empty = WeeklyHealthSnapshot(
        averageDailySteps: 0,
        priorAverageDailySteps: nil,
        averageRestingHeartRate: nil,
        averageSleepHours: nil,
        fetchedAt: .now
    )
}
