import Foundation

enum GPConcern: String, CaseIterable, Codable, Identifiable, Sendable {
    case mood
    case heart
    case labs
    case activity
    case sleep
    case metabolism

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mood: "Mood"
        case .heart: "Heart"
        case .labs: "Labs"
        case .activity: "Activity"
        case .sleep: "Sleep"
        case .metabolism: "Metabolism"
        }
    }

    var icon: String {
        switch self {
        case .mood: "brain.head.profile"
        case .heart: "heart.fill"
        case .labs: "flask.fill"
        case .activity: "figure.walk"
        case .sleep: "moon.zzz.fill"
        case .metabolism: "scalemass.fill"
        }
    }

    var matchingSignalIDs: [String] {
        switch self {
        case .mood: ["stress_somatic", "alcohol_mood", "wellbeing_dip", "activity_mood", "sleep_anxiety"]
        case .heart: ["recovery_concern", "lipid_flag", "bp_elevated"]
        case .labs: ["lipid_flag", "bp_elevated", "vitamin_d_low", "metabolic_lifestyle"]
        case .activity: ["metabolic_lifestyle", "activity_mood", "recovery_concern"]
        case .sleep: ["sleep_anxiety", "recovery_concern"]
        case .metabolism: ["metabolic_lifestyle", "vitamin_d_low"]
        }
    }
}

struct GPBriefSignalTopic: Codable, Sendable, Equatable, Identifiable {
    var id: String { signalID }
    var signalID: String
    var title: String
    var severity: String
    var evidenceSummary: String
}

struct GPVisitBrief: Codable, Sendable, Equatable {
    var reasonForVisit: String
    var discussionTopics: [GPBriefSignalTopic]
    var screeningScores: [ScreeningSnapshot]
    var physicalMeasures: LifestyleSnapshot
    var abnormalLabs: [LabFlag]
    var allLabResults: LabResults?
    var suggestedQuestions: [String]
    var geneticsNote: String?
    var dataSourcesNote: String
    var completenessPercent: Int
    var disclaimer: String
    var generatedAt: Date

    static let standardDisclaimer = """
    This brief summarises self-reported and device data. It is not a medical diagnosis. \
    Always discuss results with a qualified healthcare professional.
    """
}

enum GPBriefConsent {
    private static let key = "gpBriefConsentGiven"

    static var isGiven: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func grant() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
