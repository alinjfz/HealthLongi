import Foundation

enum OnDeviceHealthAITemplates {
    static let signalIDs: [String] = [
        "metabolic_lifestyle",
        "stress_somatic",
        "alcohol_mood",
        "recovery_concern",
        "lipid_flag",
        "wellbeing_dip",
        "activity_mood",
        "sleep_anxiety",
        "bp_elevated",
        "vitamin_d_low"
    ]

    static func explainSignal(_ signal: HealthSignal) -> String {
        let base = templateText(for: signal.id)
        if signal.evidence.isEmpty { return base }
        let evidenceSummary = signal.evidence.prefix(2).map { "\($0.label): \($0.value)" }.joined(separator: "; ")
        return "\(base) Based on your data: \(evidenceSummary)."
    }

    static func weeklyInsight(from context: PersonalHealthContext) -> String {
        if context.activeSignals.isEmpty {
            return "Your recent data looks steady. Keep completing screenings and syncing HealthKit to spot patterns early."
        }

        let titles = context.activeSignals.prefix(2).map(\.title).joined(separator: " and ")
        return "This week your device noticed \(titles.lowercased()). These are patterns worth monitoring — consider discussing any concerns with your GP."
    }

    static func suggestGPQuestions(from context: PersonalHealthContext) -> [String] {
        var questions = context.activeSignals.flatMap(\.suggestedQuestions)
        if questions.isEmpty {
            questions = [
                "Are there any screening results I should follow up on?",
                "What lifestyle changes would you recommend based on my recent data?"
            ]
        }
        return Array(questions.prefix(5))
    }

    private static func templateText(for signalID: String) -> String {
        switch signalID {
        case "metabolic_lifestyle":
            "Your HbA1c, activity, and BMI pattern together may be worth a conversation with your GP about lifestyle support."
        case "stress_somatic":
            "High stress scores alongside physical symptoms often overlap. Gentle stress management and monitoring may help."
        case "alcohol_mood":
            "Your alcohol screening and mood scores rose together. It may help to discuss this pattern with your GP."
        case "recovery_concern":
            "Your resting heart rate has increased while sleep is short. Extra rest and recovery may be helpful."
        case "lipid_flag":
            "Your LDL cholesterol is above the NHS reference range. Diet, activity, and a GP review may be useful next steps."
        case "wellbeing_dip":
            "Your wellbeing score is lower than typical. Small daily habits and social support can help — speak to your GP if it persists."
        case "activity_mood":
            "Activity has dropped while anxiety scores are elevated. Gentle movement and mood support may help together."
        case "sleep_anxiety":
            "Short sleep and higher anxiety scores often appear together. Sleep hygiene and GP advice may help if this continues."
        case "bp_elevated":
            "Your recorded blood pressure is above the NHS reference range. Home monitoring and a GP review may be appropriate."
        case "vitamin_d_low":
            "Your vitamin D is below the NHS sufficient range. Sunlight, diet, and GP guidance on supplementation may help."
        default:
            "This pattern was detected from your on-device data. Consider discussing it with your GP if you have concerns."
        }
    }
}
