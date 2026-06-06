import Foundation

struct HealthSignalEngine {
    static let maxSignals = 5

    static func evaluate(_ input: SignalEngineInput, at date: Date = .now) -> [HealthSignal] {
        var signals: [HealthSignal] = []

        if let signal = metabolicLifestyle(input, at: date) { signals.append(signal) }
        if let signal = stressSomatic(input, at: date) { signals.append(signal) }
        if let signal = alcoholMood(input, at: date) { signals.append(signal) }
        if let signal = recoveryConcern(input, at: date) { signals.append(signal) }
        if let signal = lipidFlag(input, at: date) { signals.append(signal) }
        if let signal = wellbeingDip(input, at: date) { signals.append(signal) }
        if let signal = activityMood(input, at: date) { signals.append(signal) }
        if let signal = sleepAnxiety(input, at: date) { signals.append(signal) }
        if let signal = bpElevated(input, at: date) { signals.append(signal) }
        if let signal = vitaminDLow(input, at: date) { signals.append(signal) }

        return rank(signals)
    }

    private static func rank(_ signals: [HealthSignal]) -> [HealthSignal] {
        signals
            .sorted { lhs, rhs in
                if lhs.severity != rhs.severity { return lhs.severity < rhs.severity }
                return lhs.title < rhs.title
            }
            .prefix(maxSignals)
            .map { $0 }
    }

    // MARK: - Rules

    private static func metabolicLifestyle(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard let hba1c = numericLabValue(.hba1c, in: input),
              hba1c >= 6.0 else { return nil }

        let steps = input.snapshot.averageDailySteps
        guard steps < 5000 else { return nil }

        let bmi = input.bmi ?? input.snapshot.bmi
        guard let bmi, bmi >= 25 else { return nil }

        return HealthSignal(
            id: "metabolic_lifestyle",
            kind: .correlation,
            title: "Metabolic lifestyle pattern",
            detail: "Elevated HbA1c alongside low activity and raised BMI may be worth discussing with your GP.",
            evidence: [
                EvidenceItem(source: .lab, label: "HbA1c", value: format(hba1c, unit: "%")),
                EvidenceItem(source: .healthKit, label: "Daily steps", value: "\(steps)"),
                EvidenceItem(source: .lifestyle, label: "BMI", value: format(bmi, unit: ""))
            ],
            suggestedQuestions: [
                "Could my blood sugar, weight, and activity levels be linked?",
                "What lifestyle changes might help?"
            ],
            severity: .discussWithGP,
            bodyRegion: .abdomen,
            createdAt: date
        )
    }

    private static func stressSomatic(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard input.pss10Score >= 20, input.phq15Score >= 10 else { return nil }

        return HealthSignal(
            id: "stress_somatic",
            kind: .correlation,
            title: "Stress and physical symptoms",
            detail: "High perceived stress alongside somatic symptoms may benefit from self-care and monitoring.",
            evidence: [
                EvidenceItem(source: .screening, label: "PSS-10", value: "\(input.pss10Score)/40"),
                EvidenceItem(source: .screening, label: "PHQ-15", value: "\(input.phq15Score)/30")
            ],
            suggestedQuestions: ["Could stress be contributing to my physical symptoms?"],
            severity: .watch,
            bodyRegion: .brain,
            createdAt: date
        )
    }

    private static func alcoholMood(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard input.auditCScore >= 5, input.phq9Score >= 10 else { return nil }

        return HealthSignal(
            id: "alcohol_mood",
            kind: .correlation,
            title: "Alcohol and mood overlap",
            detail: "Higher alcohol use alongside low mood scores may be worth discussing with your GP.",
            evidence: [
                EvidenceItem(source: .screening, label: "AUDIT-C", value: "\(input.auditCScore)/12"),
                EvidenceItem(source: .screening, label: "PHQ-9", value: "\(input.phq9Score)/27")
            ],
            suggestedQuestions: ["Could my alcohol use be affecting my mood?"],
            severity: .discussWithGP,
            bodyRegion: .abdomen,
            createdAt: date
        )
    }

    private static func recoveryConcern(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard let currentRHR = input.snapshot.averageRestingHeartRate,
              let priorRHR = input.priorRestingHeartRate ?? input.priorSnapshot?.averageRestingHeartRate,
              priorRHR > 0 else { return nil }

        let increase = (currentRHR - priorRHR) / priorRHR
        guard increase >= 0.10 else { return nil }

        guard let sleep = input.snapshot.averageSleepHours, sleep < 6 else { return nil }

        return HealthSignal(
            id: "recovery_concern",
            kind: .trend,
            title: "Recovery may need attention",
            detail: "Resting heart rate has risen while sleep is below 6 hours — your body may need more recovery.",
            evidence: [
                EvidenceItem(source: .healthKit, label: "Resting heart rate", value: format(currentRHR, unit: "bpm"), detail: "Up from \(format(priorRHR, unit: "bpm"))"),
                EvidenceItem(source: .healthKit, label: "Sleep average", value: SleepDurationFormatting.format(hours: sleep))
            ],
            suggestedQuestions: ["Could poor sleep be affecting my heart rate?"],
            severity: .watch,
            bodyRegion: .heart,
            createdAt: date
        )
    }

    private static func lipidFlag(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard let flag = input.labFlags.first(where: { $0.biomarker == .ldlCholesterol }) else { return nil }

        return HealthSignal(
            id: "lipid_flag",
            kind: .labFlag,
            title: "LDL cholesterol out of range",
            detail: flag.displaySummary,
            evidence: [
                EvidenceItem(source: .lab, label: flag.biomarker.label, value: format(flag.value, unit: flag.reference.unit), detail: flag.reference.nhsLabel)
            ],
            suggestedQuestions: ["What can I do to improve my cholesterol levels?"],
            severity: .discussWithGP,
            bodyRegion: .heart,
            createdAt: date
        )
    }

    private static func wellbeingDip(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard input.who5Score > 0, input.who5Score <= 12 else { return nil }

        return HealthSignal(
            id: "wellbeing_dip",
            kind: .screening,
            title: "Wellbeing score is low",
            detail: "Your WHO-5 wellbeing score suggests your general wellbeing could use attention.",
            evidence: [
                EvidenceItem(source: .screening, label: "WHO-5", value: "\(input.who5Score)/25")
            ],
            suggestedQuestions: ["What might help improve my day-to-day wellbeing?"],
            severity: .watch,
            bodyRegion: .brain,
            createdAt: date
        )
    }

    private static func activityMood(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard input.gad7Score >= 10 else { return nil }

        guard let prior = input.snapshot.priorAverageDailySteps, prior > 0 else { return nil }
        let current = input.snapshot.averageDailySteps
        let drop = Double(prior - current) / Double(prior)
        guard drop > 0.20 else { return nil }

        return HealthSignal(
            id: "activity_mood",
            kind: .correlation,
            title: "Activity drop with anxiety",
            detail: "Your step count has fallen while anxiety scores are elevated.",
            evidence: [
                EvidenceItem(source: .healthKit, label: "Daily steps", value: "\(current)", detail: "Down from \(prior)"),
                EvidenceItem(source: .screening, label: "GAD-7", value: "\(input.gad7Score)/21")
            ],
            suggestedQuestions: ["Could anxiety be affecting my activity levels?"],
            severity: .watch,
            bodyRegion: .leftKnee,
            createdAt: date
        )
    }

    private static func sleepAnxiety(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard input.gad7Score >= 10 else { return nil }
        guard let sleep = input.snapshot.averageSleepHours, sleep < 6 else { return nil }

        return HealthSignal(
            id: "sleep_anxiety",
            kind: .correlation,
            title: "Poor sleep with anxiety",
            detail: "Short sleep alongside elevated anxiety scores often go together.",
            evidence: [
                EvidenceItem(source: .healthKit, label: "Sleep average", value: SleepDurationFormatting.format(hours: sleep)),
                EvidenceItem(source: .screening, label: "GAD-7", value: "\(input.gad7Score)/21")
            ],
            suggestedQuestions: ["Could my sleep and anxiety be connected?"],
            severity: .watch,
            bodyRegion: .brain,
            createdAt: date
        )
    }

    private static func bpElevated(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        let bpFlags = input.labFlags.filter {
            $0.biomarker == .bloodPressureSystolic || $0.biomarker == .bloodPressureDiastolic
        }
        guard !bpFlags.isEmpty else { return nil }

        return HealthSignal(
            id: "bp_elevated",
            kind: .labFlag,
            title: "Blood pressure elevated",
            detail: "Your recorded blood pressure is above the NHS reference range.",
            evidence: bpFlags.map { flag in
                EvidenceItem(source: .lab, label: flag.biomarker.label, value: format(flag.value, unit: flag.reference.unit))
            },
            suggestedQuestions: ["Should I monitor my blood pressure at home?"],
            severity: .discussWithGP,
            bodyRegion: .heart,
            createdAt: date
        )
    }

    private static func vitaminDLow(_ input: SignalEngineInput, at date: Date) -> HealthSignal? {
        guard let flag = input.labFlags.first(where: { $0.biomarker == .vitaminD }) else { return nil }

        return HealthSignal(
            id: "vitamin_d_low",
            kind: .labFlag,
            title: "Vitamin D below range",
            detail: flag.displaySummary,
            evidence: [
                EvidenceItem(source: .lab, label: flag.biomarker.label, value: format(flag.value, unit: flag.reference.unit), detail: flag.reference.nhsLabel)
            ],
            suggestedQuestions: ["Should I take a vitamin D supplement?"],
            severity: .watch,
            bodyRegion: .abdomen,
            createdAt: date
        )
    }

    // MARK: - Helpers

    private static func numericLabValue(_ biomarker: LabBiomarker, in input: SignalEngineInput) -> Double? {
        if let flag = input.labFlags.first(where: { $0.biomarker == biomarker }) {
            return flag.value
        }
        guard let labs = input.labResults else { return nil }
        return LabBiomarkerIO.doubleValue(biomarker, from: labs)
    }

    private static func format(_ value: Double, unit: String) -> String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return unit.isEmpty ? formatted : "\(formatted) \(unit)"
    }
}
