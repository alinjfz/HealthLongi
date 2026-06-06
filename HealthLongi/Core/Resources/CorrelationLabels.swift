import Foundation

enum CorrelationLabels {
    static func displayName(for key: String) -> String {
        switch key {
        case "dropping_steps_with_high_gad7":
            "Daily steps have fallen while anxiety scores are elevated"
        case "poor_sleep_with_high_anxiety":
            "Short sleep and higher anxiety often appear together"
        case "poor_sleep_with_elevated_depression":
            "Short sleep alongside higher mood symptom scores"
        case "low_activity_with_elevated_depression":
            "Low activity levels with elevated mood symptom scores"
        case "elevated_glucose_with_low_activity":
            "Blood sugar markers are elevated with low daily movement"
        case "elevated_lipids_with_sedentary_lifestyle":
            "Lipid markers are elevated with limited weekly exercise"
        case "elevated_bp_with_high_resting_hr":
            "Blood pressure and resting heart rate are both elevated"
        case "low_nutrients_with_poor_sleep":
            "Low vitamin markers alongside short sleep duration"
        case "high_stress_with_poor_sleep":
            "High stress scores with consistently short sleep"
        default:
            key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
