import Foundation

struct ScreeningSnapshot: Codable, Sendable, Equatable, Identifiable {
    var id: String { kind.rawValue }
    var kind: QuestionnaireKind
    var score: Int
    var maxScore: Int
    var band: String
    var completedAt: Date
}

struct LifestyleSnapshot: Codable, Sendable, Equatable {
    var averageDailySteps: Int
    var averageRestingHeartRate: Double?
    var averageSleepHours: Double?
    var heartRateVariability: Double?
    var oxygenSaturation: Double?
    var bmi: Double?
    var weeklyExerciseMinutes: Int?
    var fetchedAt: Date

    static func from(_ snapshot: WeeklyHealthSnapshot) -> LifestyleSnapshot {
        LifestyleSnapshot(
            averageDailySteps: snapshot.averageDailySteps,
            averageRestingHeartRate: snapshot.averageRestingHeartRate,
            averageSleepHours: snapshot.averageSleepHours,
            heartRateVariability: snapshot.heartRateVariability,
            oxygenSaturation: snapshot.oxygenSaturation,
            bmi: snapshot.bmi,
            weeklyExerciseMinutes: snapshot.weeklyExerciseMinutes,
            fetchedAt: snapshot.fetchedAt
        )
    }
}

struct AppointmentPrepContext: Codable, Sendable, Equatable {
    var selectedConcerns: [String]
    var freeTextNotes: String
    var updatedAt: Date
}

struct WeeklyInsight: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var text: String
    var generatedAt: Date
    var usedTemplate: Bool
}

struct PersonalHealthContext: Codable, Sendable, Equatable {
    var lastUpdated: Date
    var activeSignals: [HealthSignal]
    var screeningSnapshot: [ScreeningSnapshot]
    var lifestyleSnapshot: LifestyleSnapshot
    var labFlags: [LabFlag]
    var appointmentPrep: AppointmentPrepContext?
    var weeklyInsightHistory: [WeeklyInsight]
    var completenessScore: Int

    static let empty = PersonalHealthContext(
        lastUpdated: .now,
        activeSignals: [],
        screeningSnapshot: [],
        lifestyleSnapshot: LifestyleSnapshot.from(.empty),
        labFlags: [],
        appointmentPrep: nil,
        weeklyInsightHistory: [],
        completenessScore: 0
    )
}
