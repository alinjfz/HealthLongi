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

    var sampleLabResults: LabResults {
        Self.makeSampleLabResults(for: self)
    }

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

    private static func makeSampleLabResults(for scenario: DemoHealthScenario) -> LabResults {
        let now = Date.now
        switch scenario.id {
        case "high_anxiety_dropping_steps":
            return LabResults(
                ast: 22, alt: 24, alp: 65,
                ft4: 14, tsh: 2.1,
                esr: 12, crp: 2.1,
                vitaminB12: 380, folate: 14, vitaminD: 42,
                cholesterol: 4.8, ldlCholesterol: 2.6, hdlCholesterol: 1.5, triglycerides: 1.2,
                bloodSugar: 5.1, hba1c: 5.4,
                egfr: 92, creatinine: 72,
                bloodPressureSystolic: 118, bloodPressureDiastolic: 76,
                waistCircumference: 78,
                lastUpdated: now
            )
        case "low_risk_active":
            return LabResults(
                ast: 20, alt: 18, alp: 58,
                ft4: 16, tsh: 1.8,
                esr: 6, crp: 0.8,
                vitaminB12: 420, folate: 18, vitaminD: 72,
                cholesterol: 4.2, ldlCholesterol: 2.1, hdlCholesterol: 1.6, triglycerides: 0.9,
                bloodSugar: 4.8, hba1c: 5.1,
                egfr: 105, creatinine: 68,
                bloodPressureSystolic: 112, bloodPressureDiastolic: 72,
                waistCircumference: 82,
                lastUpdated: now
            )
        case "metabolic_moderate_sedentary":
            return LabResults(
                ast: 28, alt: 38, alp: 82,
                ft4: 13, tsh: 2.8,
                esr: 14, crp: 3.6,
                vitaminB12: 310, folate: 9, vitaminD: 38,
                cholesterol: 6.1, ldlCholesterol: 3.8, hdlCholesterol: 1.0, triglycerides: 2.4,
                bloodSugar: 6.8, hba1c: 6.4,
                egfr: 78, creatinine: 95,
                bloodPressureSystolic: 142, bloodPressureDiastolic: 88,
                waistCircumference: 108,
                lastUpdated: now
            )
        case "poor_sleep_high_stress":
            return LabResults(
                ast: 24, alt: 26, alp: 70,
                ft4: 12, tsh: 3.6,
                esr: 18, crp: 4.2,
                vitaminB12: 340, folate: 11, vitaminD: 28,
                cholesterol: 5.4, ldlCholesterol: 3.1, hdlCholesterol: 1.3, triglycerides: 1.6,
                bloodSugar: 5.9, hba1c: 5.8,
                egfr: 88, creatinine: 78,
                bloodPressureSystolic: 128, bloodPressureDiastolic: 82,
                waistCircumference: 92,
                lastUpdated: now
            )
        case "cardio_warning_sedentary":
            return LabResults(
                ast: 26, alt: 30, alp: 76,
                ft4: 13, tsh: 2.4,
                esr: 16, crp: 5.1,
                vitaminB12: 295, folate: 8, vitaminD: 35,
                cholesterol: 6.8, ldlCholesterol: 4.2, hdlCholesterol: 0.9, triglycerides: 2.8,
                bloodSugar: 6.2, hba1c: 6.1,
                egfr: 72, creatinine: 102,
                bloodPressureSystolic: 148, bloodPressureDiastolic: 92,
                waistCircumference: 104,
                lastUpdated: now
            )
        default:
            return LabResults(lastUpdated: now)
        }
    }
}
