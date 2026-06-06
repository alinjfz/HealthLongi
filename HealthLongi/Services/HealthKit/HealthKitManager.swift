import Foundation
import HealthKit

final class HealthKitManager: HealthDataProviding, @unchecked Sendable {
    private let healthStore = HKHealthStore()

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

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

        async let currentStepsResult = averageDailySteps(from: weekAgo, to: now)
        async let priorStepsResult = averageDailySteps(from: twoWeeksAgo, to: weekAgo)
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

        let currentSteps = try await currentStepsResult
        let priorSteps = try await priorStepsResult

        return WeeklyHealthSnapshot(
            averageDailySteps: currentSteps.average,
            hasStepData: currentSteps.hasData,
            priorAverageDailySteps: priorSteps.hasData ? priorSteps.average : nil,
            activeEnergyBurned: try await activeEnergy,
            distanceWalkingRunning: try await distance,
            averageRestingHeartRate: try await restingHR,
            heartRateVariability: try await hrv,
            oxygenSaturation: normalizePercentage(try await spo2),
            averageSleepHours: try await sleep,
            bodyMass: try await mass,
            height: try await height,
            bodyFatPercentage: normalizePercentage(try await bodyFat),
            mindfulMinutes: try await mindful,
            fetchedAt: now
        )
    }

    func fetchDailySeries(for metric: HealthKitMetric, days: Int) async throws -> [DailyDataPoint] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let now = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Calendar.current.startOfDay(for: now))!

        switch metric {
        case .steps:
            return try await dailyCumulativeSeries(from: start, to: now, identifier: .stepCount, unit: .count())
        case .activeEnergy:
            return try await dailyCumulativeSeries(from: start, to: now, identifier: .activeEnergyBurned, unit: .kilocalorie())
        case .distance:
            return try await dailyCumulativeSeries(from: start, to: now, identifier: .distanceWalkingRunning, unit: .meterUnit(with: .kilo))
        case .restingHeartRate:
            return try await dailyAverageSeries(from: start, to: now, identifier: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        case .hrv:
            return try await dailyAverageSeries(from: start, to: now, identifier: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli))
        case .oxygenSaturation:
            return try await dailyAverageSeries(from: start, to: now, identifier: .oxygenSaturation, unit: .percent())
        case .bodyMass:
            return try await dailyLatestSeries(from: start, to: now, identifier: .bodyMass, unit: .gramUnit(with: .kilo))
        case .sleep:
            return try await dailySleepSeries(from: start, to: now)
        case .mindfulMinutes:
            return try await dailyMindfulSeries(from: start, to: now)
        case .height, .bodyFat:
            return []
        }
    }

    private func dailyCumulativeSeries(from start: Date, to end: Date,
                                       identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> [DailyDataPoint] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: Calendar.current.startOfDay(for: start),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, results, error in
                if let error { continuation.resume(throwing: error); return }
                guard let results else { continuation.resume(returning: []); return }

                var points: [DailyDataPoint] = []
                results.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        points.append(DailyDataPoint(date: stats.startDate, value: sum.doubleValue(for: unit)))
                    }
                }
                continuation.resume(returning: points.sorted { $0.date < $1.date })
            }
            healthStore.execute(query)
        }
    }

    private func dailyAverageSeries(from start: Date, to end: Date,
                                    identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> [DailyDataPoint] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: Calendar.current.startOfDay(for: start),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, results, error in
                if let error { continuation.resume(throwing: error); return }
                guard let results else { continuation.resume(returning: []); return }

                var points: [DailyDataPoint] = []
                results.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let avg = stats.averageQuantity() {
                        points.append(DailyDataPoint(date: stats.startDate, value: avg.doubleValue(for: unit)))
                    }
                }
                continuation.resume(returning: points.sorted { $0.date < $1.date })
            }
            healthStore.execute(query)
        }
    }

    private func dailyLatestSeries(from start: Date, to end: Date,
                                   identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> [DailyDataPoint] {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            ]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: []); return
                }
                let grouped = Dictionary(grouping: samples) { sample in
                    Calendar.current.startOfDay(for: sample.startDate)
                }
                let points = grouped.compactMap { date, daySamples -> DailyDataPoint? in
                    guard let latest = daySamples.max(by: { $0.startDate < $1.startDate }) else { return nil }
                    return DailyDataPoint(date: date, value: latest.quantity.doubleValue(for: unit))
                }.sorted { $0.date < $1.date }
                continuation.resume(returning: points)
            }
            healthStore.execute(query)
        }
    }

    private func dailySleepSeries(from start: Date, to end: Date) async throws -> [DailyDataPoint] {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: []); return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                var dailySeconds: [Date: Double] = [:]
                for sample in samples where asleepValues.contains(sample.value) {
                    let day = Calendar.current.startOfDay(for: sample.startDate)
                    dailySeconds[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate)
                }
                let points = dailySeconds.map { DailyDataPoint(date: $0.key, value: $0.value / 3600) }.sorted { $0.date < $1.date }
                continuation.resume(returning: points)
            }
            healthStore.execute(query)
        }
    }

    private func dailyMindfulSeries(from start: Date, to end: Date) async throws -> [DailyDataPoint] {
        guard let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: []); return
                }

                var dailyMinutes: [Date: Double] = [:]
                for sample in samples where sample.value == 1 {
                    let day = Calendar.current.startOfDay(for: sample.startDate)
                    dailyMinutes[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate) / 60
                }
                let points = dailyMinutes.map { DailyDataPoint(date: $0.key, value: $0.value) }.sorted { $0.date < $1.date }
                continuation.resume(returning: points)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Demographics from HealthKit

    func fetchDateOfBirth() -> Date? {
        try? healthStore.dateOfBirthComponents().date
    }

    func fetchBiologicalSex() -> HKBiologicalSex? {
        try? healthStore.biologicalSex().biologicalSex
    }

    func fetchProfileDemographics() async -> ProfileDemographicsSnapshot {
        let sex: Sex? = {
            guard let hk = fetchBiologicalSex() else { return nil }
            switch hk {
            case .female: return .female
            case .male: return .male
            default: return nil
            }
        }()

        return ProfileDemographicsSnapshot(
            dateOfBirth: fetchDateOfBirth(),
            biologicalSex: sex
        )
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

    private struct StepAverageResult {
        let average: Int
        let hasData: Bool
    }

    private func averageDailySteps(from start: Date, to end: Date) async throws -> StepAverageResult {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return StepAverageResult(average: 0, hasData: false)
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
                if let error { continuation.resume(throwing: error); return }
                guard let results else {
                    continuation.resume(returning: StepAverageResult(average: 0, hasData: false))
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
                continuation.resume(returning: StepAverageResult(average: average, hasData: days > 0))
            }

            healthStore.execute(query)
        }
    }

    private func normalizePercentage(_ value: Double?) -> Double? {
        guard let value else { return nil }
        if value > 0 && value <= 1.0 { return value * 100 }
        return value
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
