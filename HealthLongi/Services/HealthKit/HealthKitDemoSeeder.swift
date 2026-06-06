#if DEBUG
import Foundation
import HealthKit

enum HealthKitDemoSeeder {
    private static let healthStore = HKHealthStore()
    private static let daysToSeed = 14
    private static let demoMetadata = [HKMetadataKeyWasUserEntered: true]

    private static var shareTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        // appleExerciseTime is Apple-owned and cannot be written by third-party apps.
        let quantityIDs: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .distanceWalkingRunning,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .oxygenSaturation,
            .bodyMass,
            .height,
            .bodyFatPercentage
        ]
        for id in quantityIDs {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        let categoryIDs: [HKCategoryTypeIdentifier] = [.sleepAnalysis, .mindfulSession]
        for id in categoryIDs {
            if let type = HKCategoryType.categoryType(forIdentifier: id) {
                types.insert(type)
            }
        }
        types.insert(HKObjectType.workoutType())
        return types
    }

    static func seed(scenario: DemoHealthScenario) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        // Read access is required for the Assess tab to display seeded samples.
        try await healthStore.requestAuthorization(toShare: shareTypes, read: HealthKitManager.readObjectTypes)
        let samples = buildSamples(for: scenario)
        guard !samples.isEmpty else {
            throw HealthKitError.noSamplesGenerated
        }
        try await healthStore.save(samples)
    }

    private static func buildSamples(for scenario: DemoHealthScenario) -> [HKSample] {
        var samples: [HKSample] = []
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<daysToSeed {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: now)) else {
                continue
            }

            let sampleEnd: Date = {
                if dayOffset == 0 { return now }
                return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dayStart) ?? dayStart
            }()

            guard sampleEnd > dayStart else { continue }

            let isPriorWeek = dayOffset >= 7
            let baseSteps = Double(isPriorWeek ? scenario.priorDailySteps : scenario.dailySteps)
            let steps = max(500, baseSteps * dailyVariation(for: dayOffset))
            let activeEnergy = scenario.activeEnergyKcalPerDay * dailyVariation(for: dayOffset)
            let distance = scenario.distanceKmPerDay * dailyVariation(for: dayOffset)
            let restingHR = scenario.restingHeartRate + Double(dayOffset % 3) - 1
            let hrv = scenario.hrv + Double(dayOffset % 4) - 2
            let spo2 = scenario.oxygenSaturationPercent / 100.0
            let exerciseMinutes = max(1, Int((Double(scenario.weeklyExerciseMinutes) / 7.0).rounded()))
            let mindfulMinutes = max(0, scenario.mindfulMinutesPerDay * dailyVariation(for: dayOffset))

            appendQuantitySample(
                &samples,
                identifier: .stepCount,
                unit: .count(),
                value: steps,
                start: dayStart,
                end: sampleEnd,
                noLaterThan: now
            )
            appendQuantitySample(
                &samples,
                identifier: .activeEnergyBurned,
                unit: .kilocalorie(),
                value: activeEnergy,
                start: dayStart,
                end: sampleEnd,
                noLaterThan: now
            )
            appendQuantitySample(
                &samples,
                identifier: .distanceWalkingRunning,
                unit: .meterUnit(with: .kilo),
                value: distance,
                start: dayStart,
                end: sampleEnd,
                noLaterThan: now
            )

            if exerciseMinutes > 0,
               let workoutStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayStart),
               let workoutEnd = calendar.date(byAdding: .minute, value: exerciseMinutes, to: workoutStart),
               workoutEnd <= now,
               workoutEnd > workoutStart {
                let energy = HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergy * 0.35)
                let workoutDistance = HKQuantity(unit: .meterUnit(with: .kilo), doubleValue: distance * 0.45)
                samples.append(HKWorkout(
                    activityType: .walking,
                    start: workoutStart,
                    end: workoutEnd,
                    workoutEvents: nil,
                    totalEnergyBurned: energy,
                    totalDistance: workoutDistance,
                    metadata: demoMetadata
                ))
            }

            if let morning = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dayStart),
               let morningEnd = calendar.date(byAdding: .minute, value: 1, to: morning),
               morningEnd <= now,
               morningEnd > morning {
                appendQuantitySample(
                    &samples,
                    identifier: .restingHeartRate,
                    unit: HKUnit.count().unitDivided(by: .minute()),
                    value: restingHR,
                    start: morning,
                    end: morningEnd,
                    noLaterThan: now
                )
                appendQuantitySample(
                    &samples,
                    identifier: .heartRateVariabilitySDNN,
                    unit: HKUnit.secondUnit(with: .milli),
                    value: hrv,
                    start: morning,
                    end: morningEnd,
                    noLaterThan: now
                )
                appendQuantitySample(
                    &samples,
                    identifier: .oxygenSaturation,
                    unit: .percent(),
                    value: spo2,
                    start: morning,
                    end: morningEnd,
                    noLaterThan: now
                )
            }

            if mindfulMinutes > 0,
               let mindfulStart = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dayStart),
               let mindfulEnd = calendar.date(byAdding: .minute, value: Int(mindfulMinutes.rounded()), to: mindfulStart),
               mindfulEnd <= now,
               mindfulEnd > mindfulStart,
               let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
                samples.append(HKCategorySample(
                    type: mindfulType,
                    value: HKCategoryValue.notApplicable.rawValue,
                    start: mindfulStart,
                    end: mindfulEnd,
                    metadata: demoMetadata
                ))
            }

            if let sleepEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: dayStart),
               let sleepStart = calendar.date(
                   byAdding: .minute,
                   value: -Int((scenario.sleepHoursPerNight * 60).rounded()),
                   to: sleepEnd
               ),
               sleepEnd <= now,
               sleepEnd > sleepStart,
               let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
                samples.append(HKCategorySample(
                    type: sleepType,
                    value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    start: sleepStart,
                    end: sleepEnd,
                    metadata: demoMetadata
                ))
            }
        }

        let bodyStart = now.addingTimeInterval(-60)
        appendQuantitySample(&samples, identifier: .bodyMass, unit: .gramUnit(with: .kilo), value: scenario.weightKg, start: bodyStart, end: now, noLaterThan: now)
        appendQuantitySample(&samples, identifier: .height, unit: .meter(), value: scenario.heightMetres, start: bodyStart, end: now, noLaterThan: now)
        appendQuantitySample(&samples, identifier: .bodyFatPercentage, unit: .percent(), value: scenario.bodyFatPercent / 100.0, start: bodyStart, end: now, noLaterThan: now)

        return samples
    }

    private static func appendQuantitySample(
        _ samples: inout [HKSample],
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double,
        start: Date,
        end: Date,
        noLaterThan: Date
    ) {
        guard end <= noLaterThan, end > start,
              let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        samples.append(HKQuantitySample(
            type: type,
            quantity: quantity,
            start: start,
            end: end,
            metadata: demoMetadata
        ))
    }

    private static func dailyVariation(for dayOffset: Int) -> Double {
        1.0 + sin(Double(dayOffset) * 0.65) * 0.08
    }
}
#endif
