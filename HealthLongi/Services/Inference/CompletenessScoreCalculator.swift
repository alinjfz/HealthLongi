import Foundation

enum CompletenessItemID: String, CaseIterable, Codable, Identifiable, Sendable {
    case phq9
    case gad7
    case who5
    case pss10
    case auditC
    case phq15
    case healthKitCore
    case labBiomarkers
    case demographics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .phq9: "PHQ-9 questionnaire"
        case .gad7: "GAD-7 questionnaire"
        case .who5: "WHO-5 wellbeing"
        case .pss10: "PSS-10 stress"
        case .auditC: "AUDIT-C alcohol screening"
        case .phq15: "PHQ-15 physical symptoms"
        case .healthKitCore: "HealthKit steps, sleep & heart rate"
        case .labBiomarkers: "At least 5 lab biomarkers"
        case .demographics: "Profile demographics"
        }
    }

    var icon: String {
        switch self {
        case .phq9: "brain.head.profile"
        case .gad7: "waveform.path.ecg"
        case .who5: "sun.max.fill"
        case .pss10: "bolt.heart.fill"
        case .auditC: "wineglass.fill"
        case .phq15: "figure.stand"
        case .healthKitCore: "heart.text.square.fill"
        case .labBiomarkers: "cross.vial.fill"
        case .demographics: "person.fill"
        }
    }
}

struct CompletenessScoreResult: Sendable, Equatable {
    var score: Int
    var missingItems: [CompletenessItemID]
}

struct CompletenessScoreCalculator {
    static func calculate(profile: UserProfile, snapshot: WeeklyHealthSnapshot) -> CompletenessScoreResult {
        var score = 0
        var missing: [CompletenessItemID] = []

        let moodPair = profile.phq9Complete && profile.gad7Complete
        if moodPair {
            score += 25
        } else {
            if !profile.phq9Complete { missing.append(.phq9) }
            if !profile.gad7Complete { missing.append(.gad7) }
        }

        let wellbeingPair = profile.who5Complete && profile.pss10Complete
        if wellbeingPair {
            score += 15
        } else {
            if !profile.who5Complete { missing.append(.who5) }
            if !profile.pss10Complete { missing.append(.pss10) }
        }

        let lifestylePair = profile.auditCComplete && profile.phq15Complete
        if lifestylePair {
            score += 10
        } else {
            if !profile.auditCComplete { missing.append(.auditC) }
            if !profile.phq15Complete { missing.append(.phq15) }
        }

        let healthKitCore = snapshot.hasStepData
            && snapshot.averageSleepHours != nil
            && snapshot.averageRestingHeartRate != nil
        if healthKitCore {
            score += 20
        } else {
            missing.append(.healthKitCore)
        }

        let labCount = biomarkerCount(in: profile.labResults)
        if labCount >= 5 {
            score += 15
        } else {
            missing.append(.labBiomarkers)
        }

        if profile.onboardingComplete {
            score += 15
        } else {
            missing.append(.demographics)
        }

        return CompletenessScoreResult(score: min(score, 100), missingItems: missing)
    }

    private static func biomarkerCount(in labs: LabResults?) -> Int {
        guard let labs else { return 0 }
        return LabBiomarker.coreReferenceBiomarkers.filter {
            LabBiomarkerIO.doubleValue($0, from: labs) != nil
        }.count
    }
}
