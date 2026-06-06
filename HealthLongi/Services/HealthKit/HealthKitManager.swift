import Foundation
import HealthKit

final class HealthKitManager: HealthDataProviding, @unchecked Sendable {
    private let healthStore = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHR)
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchWeeklySnapshot() async throws -> WeeklyHealthSnapshot {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        async let currentSteps = averageDailySteps(from: weekAgo, to: now)
        async let priorSteps = averageDailySteps(from: twoWeeksAgo, to: weekAgo)
        async let restingHR = averageRestingHeartRate(from: weekAgo, to: now)
        async let sleep = averageSleepHours(from: weekAgo, to: now)

        return WeeklyHealthSnapshot(
            averageDailySteps: try await currentSteps,
            priorAverageDailySteps: try await priorSteps,
            averageRestingHeartRate: try await restingHR,
            averageSleepHours: try await sleep,
            fetchedAt: now
        )
    }

    private func averageDailySteps(from start: Date, to end: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: Calendar.current.startOfDay(for: start),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let results else {
                    continuation.resume(returning: 0)
                    return
                }

                var total = 0.0
                var days = 0
                results.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        total += sum.doubleValue(for: .count())
                        days += 1
                    }
                }
                let average = days > 0 ? Int(total / Double(days)) : 0
                continuation.resume(returning: average)
            }

            healthStore.execute(query)
        }
    }

    private func averageRestingHeartRate(from start: Date, to end: Date) async throws -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let avg = result?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            healthStore.execute(query)
        }
    }

    private func averageSleepHours(from start: Date, to end: Date) async throws -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                var totalSeconds = 0.0
                for sample in samples where asleepValues.contains(sample.value) {
                    totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }

                let days = max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 7)
                continuation.resume(returning: totalSeconds / 3600.0 / Double(days))
            }
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            "HealthKit is not available on this device."
        }
    }
}
