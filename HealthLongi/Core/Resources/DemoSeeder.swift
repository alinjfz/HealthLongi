import Foundation
import SwiftData

extension Notification.Name {
    static let demoHealthDataDidSeed = Notification.Name("demoHealthDataDidSeed")
}

enum DemoSeeder {
    struct SeedResult: Sendable {
        let scenarioTitle: String
        let healthKitMessage: String?
    }

    /// Seeds app profile data and writes matching HealthKit samples for the selected scenario.
    @MainActor
    static func seed(scenario: DemoHealthScenario, context: ModelContext) async -> SeedResult {
        let profile: UserProfile
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            profile = existing
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        profile.dateOfBirth = Calendar.current.date(byAdding: .year, value: -scenario.age, to: .now) ?? .now
        profile.sex = scenario.sex
        profile.smokingStatus = scenario.smokingStatus
        profile.onboardingComplete = true
        profile.phq9Score = scenario.phq9Score
        profile.gad7Score = scenario.gad7Score
        profile.phq9Complete = true
        profile.gad7Complete = true
        profile.phq9CompletedAt = .now
        profile.gad7CompletedAt = .now
        profile.bmi = scenario.bmi
        profile.weightKg = scenario.weightKg
        profile.heightCm = scenario.heightMetres * 100
        profile.physicalActivityMinutes = scenario.weeklyExerciseMinutes
        profile.labResults = scenario.sampleLabResults
        profile.labImportHistory = [
            LabImportRecord(
                sourceFilename: "Demo — \(scenario.title).pdf",
                biomarkerCount: scenario.sampleLabResults.hasAnyValue ? 20 : 0,
                biomarkerLabels: [
                    "Total cholesterol", "LDL cholesterol", "HDL cholesterol", "Triglycerides",
                    "Fasting glucose", "HbA1c", "Systolic BP", "Diastolic BP",
                    "AST", "ALT", "TSH", "Free T4", "Vitamin D", "Vitamin B12",
                    "Folate", "eGFR", "Creatinine", "ESR", "hsCRP", "Waist circumference"
                ],
                reportDate: .now
            )
        ]

        try? context.save()

        #if DEBUG
        do {
            try await HealthKitDemoSeeder.seed(scenario: scenario)
        } catch {
            return SeedResult(
                scenarioTitle: scenario.title,
                healthKitMessage: "Profile saved, but Apple Health could not be updated: \(error.localizedDescription)"
            )
        }

        var verification = "Apple Health data saved."
        do {
            let manager = HealthKitManager()
            try await manager.requestAuthorization()
            let snapshot = try await manager.fetchWeeklySnapshot()
            verification = verifySnapshot(snapshot, expectedSteps: scenario.dailySteps)
        } catch {
            verification = "Data saved, but read-back check failed: \(error.localizedDescription)"
        }

        NotificationCenter.default.post(name: .demoHealthDataDidSeed, object: nil)

        return SeedResult(
            scenarioTitle: scenario.title,
            healthKitMessage: """
            Profile, sample lab results, and Apple Health data loaded. \(verification)
            If Assess still looks empty, open Settings → Health → Data Access and enable all read permissions for this app.
            """
        )
        #else
        return SeedResult(
            scenarioTitle: scenario.title,
            healthKitMessage: nil
        )
        #endif
    }

    #if DEBUG
    private static func verifySnapshot(_ snapshot: WeeklyHealthSnapshot, expectedSteps: Int) -> String {
        guard snapshot.hasStepData else {
            return "Saved to Health, but the app cannot read it back yet — allow read access when prompted."
        }

        let steps = snapshot.averageDailySteps
        let tolerance = max(500, Int(Double(expectedSteps) * 0.2))
        if abs(steps - expectedSteps) <= tolerance {
            return "Verified \(steps.formatted()) steps/day in Apple Health."
        }
        return "Health data saved (\(steps.formatted()) steps/day detected)."
    }
    #endif
}
