import SwiftUI

struct WaistHeightCalculatorView: View {
    let profile: UserProfile?
    let snapshot: WeeklyHealthSnapshot

    @State private var waistCm = ""
    @State private var heightCm = ""

    var body: some View {
        CalculatorSheetContainer(title: "Waist-to-Height") {
            VStack(alignment: .leading, spacing: 16) {
                Text("A waist measurement less than half your height is a simple check recommended by NHS guidance.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)

                TextField("Waist (cm)", text: $waistCm)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Height (cm)", text: $heightCm)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                if let result = calculate() {
                    CalculatorResultCard(
                        title: result.title,
                        message: result.message,
                        color: result.color,
                        tip: "Try to keep active and maintain a balanced diet — small changes add up."
                    )
                }
            }
            .onAppear {
                if heightCm.isEmpty, let h = snapshot.height {
                    heightCm = String(format: "%.0f", h * 100)
                }
                if waistCm.isEmpty, let w = profile?.labResults?.waistCircumference {
                    waistCm = String(format: "%.0f", w)
                }
            }
        }
    }

    private func calculate() -> (title: String, message: String, color: Color)? {
        guard let waist = Double(waistCm), let height = Double(heightCm), height > 0 else { return nil }
        let ratio = waist / height
        if ratio < 0.5 {
            return ("In a healthy range", String(format: "Your ratio is %.2f — below 0.5 is a good sign.", ratio), .green)
        }
        return ("Worth keeping an eye on", String(format: "Your ratio is %.2f. NHS suggests keeping waist below half your height.", ratio), .orange)
    }
}

struct IdealWeightCalculatorView: View {
    let profile: UserProfile?
    let snapshot: WeeklyHealthSnapshot

    @State private var heightCm = ""

    var body: some View {
        CalculatorSheetContainer(title: "Healthy Weight") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Height (cm)", text: $heightCm)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                if let h = Double(heightCm), h > 0 {
                    let minKg = 18.5 * pow(h / 100, 2)
                    let maxKg = 24.9 * pow(h / 100, 2)
                    CalculatorResultCard(
                        title: "Healthy weight range",
                        message: String(format: "%.0f – %.0f kg (%.0f – %.0f lb)", minKg, maxKg, minKg / 0.453592, maxKg / 0.453592),
                        color: NHSTheme.primaryBlue,
                        tip: "This is a screening range based on BMI 18.5–24.9, not a personal target."
                    )
                }
            }
            .onAppear {
                if heightCm.isEmpty, let h = profile?.heightCm ?? snapshot.height.map({ $0 * 100 }) {
                    heightCm = String(format: "%.0f", h)
                }
            }
        }
    }
}

struct CalorieCalculatorView: View {
    let profile: UserProfile?
    let snapshot: WeeklyHealthSnapshot

    @State private var weightKg = ""
    @State private var heightCm = ""
    @State private var age = ""
    @State private var sex: Sex = .female
    @State private var activity: ActivityLevel = .moderate

    enum ActivityLevel: String, CaseIterable, Identifiable {
        case sedentary, light, moderate, active
        var id: String { rawValue }
        var multiplier: Double {
            switch self {
            case .sedentary: 1.2
            case .light: 1.375
            case .moderate: 1.55
            case .active: 1.725
            }
        }
        var label: String {
            switch self {
            case .sedentary: "Mostly sitting"
            case .light: "Light activity"
            case .moderate: "Moderate activity"
            case .active: "Very active"
            }
        }
    }

    var body: some View {
        CalculatorSheetContainer(title: "Daily Calories") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Weight (kg)", text: $weightKg).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                TextField("Height (cm)", text: $heightCm).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                TextField("Age", text: $age).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                Picker("Sex", selection: $sex) {
                    ForEach(Sex.allCases) { s in Text(s.displayName).tag(s) }
                }
                Picker("Activity", selection: $activity) {
                    ForEach(ActivityLevel.allCases) { level in Text(level.label).tag(level) }
                }

                if let kcal = calculate() {
                    CalculatorResultCard(
                        title: "Estimated daily calories",
                        message: "About \(Int(kcal)) kcal per day to maintain your current weight.",
                        color: NHSTheme.primaryBlue,
                        tip: "NHS Eatwell Guide: plenty of fruit, veg, and whole grains."
                    )
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        if let p = profile {
            age = "\(p.age)"
            sex = p.sex
        }
        if weightKg.isEmpty, let w = profile?.weightKg ?? snapshot.bodyMass {
            weightKg = String(format: "%.1f", w)
        }
        if heightCm.isEmpty, let h = profile?.heightCm ?? snapshot.height.map({ $0 * 100 }) {
            heightCm = String(format: "%.0f", h)
        }
    }

    private func calculate() -> Double? {
        guard let w = Double(weightKg), let h = Double(heightCm), let a = Int(age), w > 0, h > 0 else { return nil }
        let bmr: Double
        if sex == .male {
            bmr = 10 * w + 6.25 * h - 5 * Double(a) + 5
        } else {
            bmr = 10 * w + 6.25 * h - 5 * Double(a) - 161
        }
        return bmr * activity.multiplier
    }
}

struct HeartRateZoneCalculatorView: View {
    let profile: UserProfile?

    @State private var age = ""

    var body: some View {
        CalculatorSheetContainer(title: "Heart Rate Zones") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Age", text: $age).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                if let a = Int(age), a > 0 {
                    let maxHR = 220 - a
                    CalculatorResultCard(
                        title: "Estimated zones",
                        message: """
                        Light (50–60%): \(Int(Double(maxHR) * 0.5))–\(Int(Double(maxHR) * 0.6)) bpm
                        Moderate (60–70%): \(Int(Double(maxHR) * 0.6))–\(Int(Double(maxHR) * 0.7)) bpm — brisk walk
                        Vigorous (70–85%): \(Int(Double(maxHR) * 0.7))–\(Int(Double(maxHR) * 0.85)) bpm
                        """,
                        color: NHSTheme.primaryBlue,
                        tip: "NHS recommends 150 minutes of moderate activity per week."
                    )
                }
            }
            .onAppear {
                if age.isEmpty, let p = profile { age = "\(p.age)" }
            }
        }
    }
}

struct WaterIntakeCalculatorView: View {
    let profile: UserProfile?
    let snapshot: WeeklyHealthSnapshot

    @State private var weightKg = ""

    var body: some View {
        CalculatorSheetContainer(title: "Water Intake") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Weight (kg)", text: $weightKg).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                if let w = Double(weightKg), w > 0 {
                    let ml = w * 35
                    let cups = ml / 250
                    CalculatorResultCard(
                        title: "Daily hydration guide",
                        message: String(format: "About %.0f ml (%.0f cups) per day as a rough guide.", ml, cups),
                        color: NHSTheme.primaryBlue,
                        tip: "Drink more when exercising or in hot weather."
                    )
                }
            }
            .onAppear {
                if weightKg.isEmpty, let w = profile?.weightKg ?? snapshot.bodyMass {
                    weightKg = String(format: "%.1f", w)
                }
            }
        }
    }
}

struct AlcoholUnitsCalculatorView: View {
    @State private var volumeMl = ""
    @State private var abv = ""

    var body: some View {
        CalculatorSheetContainer(title: "Alcohol Units") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Volume (ml)", text: $volumeMl).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                TextField("ABV (%)", text: $abv).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)

                if let units = calculate() {
                    let color: Color = units <= 2 ? .green : units <= 4 ? .orange : .red
                    CalculatorResultCard(
                        title: String(format: "%.1f units", units),
                        message: units <= 14
                            ? "NHS low-risk guideline: no more than 14 units per week, spread over 3+ days."
                            : "This exceeds the weekly NHS low-risk guideline of 14 units.",
                        color: color,
                        tip: "Consider alcohol-free days each week."
                    )
                }
            }
        }
    }

    private func calculate() -> Double? {
        guard let vol = Double(volumeMl), let strength = Double(abv), vol > 0, strength > 0 else { return nil }
        return vol * strength / 1000
    }
}

struct BloodPressureCalculatorView: View {
    let profile: UserProfile?

    @State private var systolic = ""
    @State private var diastolic = ""

    var body: some View {
        CalculatorSheetContainer(title: "Blood Pressure") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Systolic (mmHg)", text: $systolic).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                TextField("Diastolic (mmHg)", text: $diastolic).keyboardType(.numberPad).textFieldStyle(.roundedBorder)

                if let result = categorize() {
                    CalculatorResultCard(title: result.title, message: result.message, color: result.color, tip: result.tip)
                }
            }
            .onAppear {
                if let labs = profile?.labResults {
                    if systolic.isEmpty, let s = labs.bloodPressureSystolic { systolic = "\(s)" }
                    if diastolic.isEmpty, let d = labs.bloodPressureDiastolic { diastolic = "\(d)" }
                }
            }
        }
    }

    private func categorize() -> (title: String, message: String, color: Color, tip: String)? {
        guard let sys = Int(systolic), let dia = Int(diastolic) else { return nil }
        if sys < 120 && dia < 80 {
            return ("Normal", "Your reading is within the normal NHS range.", .green, "Keep up healthy habits.")
        }
        if sys < 140 && dia < 90 {
            return ("High normal", "Slightly raised — lifestyle changes may help.", .orange, "Reduce salt and stay active.")
        }
        return ("High", "This reading is high — consider speaking to your GP.", .red, "NHS offers free blood pressure checks at many pharmacies.")
    }
}

struct DiabetesRiskCalculatorView: View {
    let profile: UserProfile?
    let snapshot: WeeklyHealthSnapshot

    @State private var age = ""
    @State private var bmi = ""
    @State private var waist = ""
    @State private var activityMinutes = ""
    @State private var familyHistory = false

    var body: some View {
        CalculatorSheetContainer(title: "Diabetes Risk") {
            VStack(alignment: .leading, spacing: 16) {
                Text("A simplified FINDRISC-style check — not a diagnosis.")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)

                TextField("Age", text: $age).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                TextField("BMI", text: $bmi).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                TextField("Waist (cm)", text: $waist).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                TextField("Activity (min/week)", text: $activityMinutes).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                Toggle("Family history of diabetes", isOn: $familyHistory)

                if let band = riskBand() {
                    CalculatorResultCard(title: band.title, message: band.message, color: band.color, tip: band.tip)
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        if let p = profile {
            age = "\(p.age)"
            if let b = p.bmi { bmi = String(format: "%.1f", b) }
            if let a = p.physicalActivityMinutes { activityMinutes = "\(a)" }
            if let w = p.labResults?.waistCircumference { waist = String(format: "%.0f", w) }
        }
    }

    private func riskBand() -> (title: String, message: String, color: Color, tip: String)? {
        guard let a = Int(age), let b = Double(bmi) else { return nil }
        var points = 0
        if a >= 45 { points += 2 } else if a >= 35 { points += 1 }
        if b >= 30 { points += 3 } else if b >= 25 { points += 1 }
        if let w = Double(waist) {
            let threshold = profile?.sex == .male ? 94.0 : 80.0
            if w >= threshold + 14 { points += 3 } else if w >= threshold { points += 2 }
        }
        if let mins = Int(activityMinutes), mins < 30 { points += 2 }
        if familyHistory { points += 3 }

        switch points {
        case 0...6:
            return ("Lower estimated risk", "Your answers suggest a lower chance of type 2 diabetes — keep up healthy habits.", .green, "NHS Diabetes Prevention Programme is free for eligible people.")
        case 7...11:
            return ("Moderate estimated risk", "Some factors suggest moderate risk — small lifestyle changes can help.", .orange, "Consider a GP chat about a blood sugar check.")
        default:
            return ("Higher estimated risk", "Several factors suggest higher risk — a GP check is worth considering.", .red, "Type 2 diabetes is often preventable with early action.")
        }
    }
}
