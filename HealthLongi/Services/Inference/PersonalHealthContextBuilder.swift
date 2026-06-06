import Foundation

struct PersonalHealthContextBuilder {
    static func build(
        profile: UserProfile,
        snapshot: WeeklyHealthSnapshot,
        signals: [HealthSignal],
        at date: Date = .now
    ) -> PersonalHealthContext {
        let labFlags = LabFlagEvaluator.evaluate(labs: profile.labResults ?? .empty, at: date)

        return PersonalHealthContext(
            lastUpdated: date,
            activeSignals: signals,
            screeningSnapshot: screeningEntries(from: profile),
            lifestyleSnapshot: LifestyleSnapshot.from(snapshot),
            labFlags: labFlags,
            appointmentPrep: profile.personalHealthContext?.appointmentPrep,
            weeklyInsightHistory: profile.personalHealthContext?.weeklyInsightHistory ?? [],
            completenessScore: profile.personalHealthContext?.completenessScore ?? 0
        )
    }

    @discardableResult
    static func rebuild(
        profile: UserProfile,
        snapshot: WeeklyHealthSnapshot,
        at date: Date = .now
    ) -> PersonalHealthContext {
        let labFlags = LabFlagEvaluator.evaluate(labs: profile.labResults ?? .empty, at: date)
        let input = SignalEngineInput.from(profile: profile, snapshot: snapshot, labFlags: labFlags)
        let signals = HealthSignalEngine.evaluate(input, at: date)
        let context = build(profile: profile, snapshot: snapshot, signals: signals, at: date)
        profile.personalHealthContext = context
        return context
    }

    private static func screeningEntries(from profile: UserProfile) -> [ScreeningSnapshot] {
        QuestionnaireKind.activeCases.compactMap { kind in
            guard profile.isComplete(kind) else { return nil }
            let score = profile.score(for: kind)
            return ScreeningSnapshot(
                kind: kind,
                score: score,
                maxScore: kind.maxScore,
                band: kind.band(for: score),
                completedAt: profile.completedAt(kind) ?? profile.createdAt
            )
        }
    }
}

private extension QuestionnaireKind {
    var maxScore: Int {
        switch self {
        case .phq9: 27
        case .gad7: 21
        case .who5: 25
        case .pss10: 40
        case .sleep: 25
        case .auditC: 12
        case .phq15: 30
        }
    }

    func band(for score: Int) -> String {
        switch self {
        case .phq9:
            switch score {
            case 0...4: "Minimal"
            case 5...9: "Mild"
            case 10...14: "Moderate"
            case 15...19: "Moderately severe"
            default: "Severe"
            }
        case .gad7:
            switch score {
            case 0...4: "Minimal"
            case 5...9: "Mild"
            case 10...14: "Moderate"
            default: "Severe"
            }
        case .who5:
            score <= 12 ? "Low wellbeing" : score <= 18 ? "Moderate" : "Good"
        case .pss10:
            score <= 13 ? "Low stress" : score <= 26 ? "Moderate" : "High stress"
        case .sleep:
            "Recorded"
        case .auditC:
            switch score {
            case 0...3: "Low risk"
            case 4...5: "Increasing risk"
            default: "Higher risk"
            }
        case .phq15:
            score <= 4 ? "Minimal" : score <= 9 ? "Mild" : score <= 14 ? "Moderate" : "Severe"
        }
    }
}

private extension UserProfile {
    func score(for kind: QuestionnaireKind) -> Int {
        switch kind {
        case .phq9: phq9Score
        case .gad7: gad7Score
        case .who5: who5Score
        case .pss10: pss10Score
        case .sleep: sleepScore
        case .auditC: auditCScore
        case .phq15: phq15Score
        }
    }
}
