import Foundation
import HealthKit

final class HealthKitManager: HealthDataProviding, @unchecked Sendable {
    private let healthStore = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        // Activity
        if let t = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(t) }
        // Vitals
        if let t = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) { types.insert(t) }
        // Sleep
        if let t = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(t) }
        // Body
        if let t = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .height) { types.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) { types.insert(t) }
        // Mindfulness
        if let t = HKCategoryType.categoryType(forIdentifier: .mindfulSession) { types.insert(t) }
        // Demographics (read-only, single sample)
        if let t = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) { types.insert(t) }
        if let t = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex) { types.insert(t) }
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
        async let activeEnergy = averageQuantity(from: weekAgo, to: now,
            identifier: .activeEnergyBurned, unit: .kilocalorie(), perDay: true)
        async let distance = averageQuantity(from: weekAgo, to: now,
            identifier: .distanceWalkingRunning, unit: .meterUnit(with: .kilo), perDay: true)
        async let restingHR = averageRestingHeartRate(from: weekAgo, to: now)
        async let hrv = averageQuantity(from: weekAgo, to: now,
            identifier: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), perDay: false)
        async let spo2 = averageQuantity(from: weekAgo, to: now,
            identifier: .oxygenSaturation, unit: .percent(), perDay: false)
        async let sleep = averageSleepHours(from: weekAgo, to: now)
        async let mass = latestQuantity(for: .bodyMass, unit: .gramUnit(with: .kilo))
        async let height = latestQuantity(for: .height, unit: .meter())
        async let bodyFat = latestQuantity(for: .bodyFatPercentage, unit: .percent())
        async let mindful = averageMindfulMinutes(from: weekAgo, to: now)

        return WeeklyHealthSnapshot(
            averageDailySteps: try await currentSteps,
            priorAverageDailySteps: try await priorSteps,
            activeEnergyBurned: try await activeEnergy,
            distanceWalkingRunning: try await distance,
            averageRestingHeartRate: try await restingHR,
            heartRateVariability: try await hrv,
            oxygenSaturation: try await spo2,
            averageSleepHours: try await sleep,
            bodyMass: try await mass,
            height: try await height,
            bodyFatPercentage: try await bodyFat,
            mindfulMinutes: try await mindful,
            fetchedAt: now
        )
    }

    // MARK: - Demographics from HealthKit

    func fetchDateOfBirth() -> Date? {
        try? healthStore.dateOfBirthComponents().date
    }

    func fetchBiologicalSex() -> HKBiologicalSex? {
        try? healthStore.biologicalSex().biologicalSex
    }

    // MARK: - Generic quantity helpers

    private func averageQuantity(from start: Date, to end: Date,
                                  identifier: HKQuantityTypeIdentifier, unit: HKUnit,
                                  perDay: Bool) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

            if perDay {
                let query = HKStatisticsCollectionQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: Calendar.current.startOfDay(for: start),
                    intervalComponents: DateComponents(day: 1)
                )
                query.initialResultsHandler = { _, results, error in
                    if let error { continuation.resume(throwing: error); return }
                    guard let results else { continuation.resume(returning: nil); return }

                    var total = 0.0
                    var days = 0
                    results.enumerateStatistics(from: start, to: end) { stats, _ in
                        if let sum = stats.sumQuantity() {
                            total += sum.doubleValue(for: unit)
                            days += 1
                        }
                    }
                    continuation.resume(returning: days > 0 ? total / Double(days) : nil)
                }
                healthStore.execute(query)
            } else {
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .discreteAverage
                ) { _, result, error in
                    if let error { continuation.resume(throwing: error); return }
                    guard let avg = result?.averageQuantity() else {
                        continuation.resume(returning: nil); return
                    }
                    continuation.resume(returning: avg.doubleValue(for: unit))
                }
                healthStore.execute(query)
            }
        }
    }

    private func latestQuantity(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil); return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Step Count

    private func averageDailySteps(from start: Date, to end: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

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
                if let error { continuation.resume(throwing: error); return }
                guard let results else { continuation.resume(returning: 0); return }

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

    // MARK: - Resting Heart Rate

    private func averageRestingHeartRate(from start: Date, to end: Date) async throws -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                guard let avg = result?.averageQuantity() else {
                    continuation.resume(returning: nil); return
                }
                continuation.resume(returning: avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Sleep

    private func averageSleepHours(from start: Date, to end: Date) async throws -> Double? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil); return
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

    // MARK: - Mindful Minutes

    private func averageMindfulMinutes(from start: Date, to end: Date) async throws -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil); return
                }

                var totalMinutes = 0.0
                for sample in samples where sample.value == 1 { // mindful = 1
                    totalMinutes += sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                }

                let days = max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 7)
                continuation.resume(returning: totalMinutes / Double(days))
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
