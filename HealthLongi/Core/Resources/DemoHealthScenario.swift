import Foundation

struct DemoHealthScenario: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String

    let age: Int
    let sex: Sex
    let smokingStatus: SmokingStatus
    let phq9Score: Int
    let gad7Score: Int

    let heightMetres: Double
    let bmi: Double
    let bodyFatPercent: Double

    let dailySteps: Int
    let priorDailySteps: Int
    let activeEnergyKcalPerDay: Double
    let distanceKmPerDay: Double
    let weeklyExerciseMinutes: Int
    let mindfulMinutesPerDay: Double

    let restingHeartRate: Double
    let hrv: Double
    let oxygenSaturationPercent: Double
    let sleepHoursPerNight: Double

    var weightKg: Double { bmi * heightMetres * heightMetres }

    static let all: [DemoHealthScenario] = [
        DemoHealthScenario(
            id: "high_anxiety_dropping_steps",
            title: "Anxious & Less Active",
            subtitle: "32-year-old woman — rising anxiety, steps falling from 7,200 to 3,500/day",
            age: 32,
            sex: .female,
            smokingStatus: .never,
            phq9Score: 8,
            gad7Score: 14,
            heightMetres: 1.65,
            bmi: 24.5,
            bodyFatPercent: 28,
            dailySteps: 3500,
            priorDailySteps: 7200,
            activeEnergyKcalPerDay: 210,
            distanceKmPerDay: 2.4,
            weeklyExerciseMinutes: 20,
            mindfulMinutesPerDay: 2,
            restingHeartRate: 76,
            hrv: 34,
            oxygenSaturationPercent: 97,
            sleepHoursPerNight: 5.2
        ),
        DemoHealthScenario(
            id: "low_risk_active",
            title: "Healthy & Active",
            subtitle: "28-year-old man — low risk across heart, mind, and metabolism",
            age: 28,
            sex: .male,
            smokingStatus: .never,
            phq9Score: 2,
            gad7Score: 1,
            heightMetres: 1.78,
            bmi: 22.0,
            bodyFatPercent: 15,
            dailySteps: 9500,
            priorDailySteps: 9100,
            activeEnergyKcalPerDay: 480,
            distanceKmPerDay: 6.8,
            weeklyExerciseMinutes: 180,
            mindfulMinutesPerDay: 12,
            restingHeartRate: 62,
            hrv: 58,
            oxygenSaturationPercent: 98,
            sleepHoursPerNight: 7.5
        ),
        DemoHealthScenario(
            id: "metabolic_moderate_sedentary",
            title: "Metabolic Risk",
            subtitle: "58-year-old man — sedentary, higher BMI, former smoker",
            age: 58,
            sex: .male,
            smokingStatus: .former,
            phq9Score: 6,
            gad7Score: 4,
            heightMetres: 1.75,
            bmi: 31.2,
            bodyFatPercent: 32,
            dailySteps: 2800,
            priorDailySteps: 3100,
            activeEnergyKcalPerDay: 180,
            distanceKmPerDay: 1.9,
            weeklyExerciseMinutes: 15,
            mindfulMinutesPerDay: 0,
            restingHeartRate: 74,
            hrv: 38,
            oxygenSaturationPercent: 96,
            sleepHoursPerNight: 6.0
        ),
        DemoHealthScenario(
            id: "poor_sleep_high_stress",
            title: "Poor Sleep & Stress",
            subtitle: "45-year-old woman — short sleep, moderate mood and anxiety scores",
            age: 45,
            sex: .female,
            smokingStatus: .never,
            phq9Score: 11,
            gad7Score: 10,
            heightMetres: 1.62,
            bmi: 27.0,
            bodyFatPercent: 34,
            dailySteps: 4800,
            priorDailySteps: 5200,
            activeEnergyKcalPerDay: 260,
            distanceKmPerDay: 3.1,
            weeklyExerciseMinutes: 30,
            mindfulMinutesPerDay: 3,
            restingHeartRate: 72,
            hrv: 31,
            oxygenSaturationPercent: 97,
            sleepHoursPerNight: 4.8
        ),
        DemoHealthScenario(
            id: "cardio_warning_sedentary",
            title: "Cardio Strain",
            subtitle: "62-year-old man — low activity, elevated resting heart rate",
            age: 62,
            sex: .male,
            smokingStatus: .former,
            phq9Score: 5,
            gad7Score: 3,
            heightMetres: 1.72,
            bmi: 29.0,
            bodyFatPercent: 30,
            dailySteps: 2200,
            priorDailySteps: 2600,
            activeEnergyKcalPerDay: 160,
            distanceKmPerDay: 1.5,
            weeklyExerciseMinutes: 10,
            mindfulMinutesPerDay: 0,
            restingHeartRate: 84,
            hrv: 26,
            oxygenSaturationPercent: 95,
            sleepHoursPerNight: 5.8
        )
    ]
}
