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
}

struct AppointmentPrepContext: Codable, Sendable, Equatable {
    var selectedConcerns: [String]
    var freeTextNotes: String
    var updatedAt: Date
}

struct GPBriefSignalTopic: Sendable, Equatable, Identifiable {
    var id: String { signalID }
    var signalID: String
    var title: String
    var severity: String
    var evidenceSummary: String
}

struct ScreeningSnapshot: Sendable, Equatable, Identifiable {
    var id: String { kind.rawValue }
    var kind: QuestionnaireKind
    var score: Int
    var maxScore: Int
    var band: String
    var completedAt: Date
}

struct LifestyleSnapshot: Sendable, Equatable {
    var averageDailySteps: Int
    var averageRestingHeartRate: Double?
    var averageSleepHours: Double?
    var bmi: Double?

    static func from(_ snapshot: WeeklyHealthSnapshot) -> LifestyleSnapshot {
        LifestyleSnapshot(
            averageDailySteps: snapshot.averageDailySteps,
            averageRestingHeartRate: snapshot.averageRestingHeartRate,
            averageSleepHours: snapshot.averageSleepHours,
            bmi: snapshot.bmi ?? snapshot.bodyMass.flatMap { _ in snapshot.bmi }
        )
    }
}

struct LabReferenceRange: Sendable, Equatable {
    var min: Double?
    var max: Double?
    var unit: String
    var nhsLabel: String
}

struct LabFlag: Sendable, Equatable, Identifiable {
    enum Direction: String, Codable, Sendable {
        case above
        case below
    }

    var biomarker: LabBiomarker
    var value: Double
    var reference: LabReferenceRange
    var direction: Direction
    var flaggedAt: Date

    var id: String { biomarker.rawValue }

    var displaySummary: String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        let directionText = direction == .above ? "above" : "below"
        return "\(biomarker.label): \(formatted) \(reference.unit) (\(directionText) NHS range)"
    }
}

struct GPVisitBrief: Sendable, Equatable {
    var reasonForVisit: String
    var discussionTopics: [GPBriefSignalTopic]
    var screeningScores: [ScreeningSnapshot]
    var physicalMeasures: LifestyleSnapshot
    var abnormalLabs: [LabFlag]
    var allLabResults: LabResults?
    var suggestedQuestions: [String]
    var geneticsNote: String?
    var dataSourcesNote: String
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

extension LabBiomarker {
    static let coreReferenceBiomarkers: [LabBiomarker] = [
        .hba1c, .ldlCholesterol, .hdlCholesterol, .cholesterol, .bloodSugar,
        .vitaminD, .tsh, .bloodPressureSystolic, .bloodPressureDiastolic,
        .crp, .egfr
    ]

    var referenceRange: LabReferenceRange? {
        switch self {
        case .hba1c:
            LabReferenceRange(min: nil, max: 6.0, unit: unit, nhsLabel: "Non-diabetic: below 6.0%")
        case .ldlCholesterol:
            LabReferenceRange(min: nil, max: 3.0, unit: unit, nhsLabel: "Desirable: below 3.0 mmol/L")
        case .hdlCholesterol:
            LabReferenceRange(min: 1.0, max: nil, unit: unit, nhsLabel: "Desirable: 1.0 mmol/L or above")
        case .cholesterol:
            LabReferenceRange(min: nil, max: 5.0, unit: unit, nhsLabel: "Desirable: below 5.0 mmol/L")
        case .bloodSugar:
            LabReferenceRange(min: 3.9, max: 5.5, unit: unit, nhsLabel: "Normal fasting: 3.9–5.5 mmol/L")
        case .vitaminD:
            LabReferenceRange(min: 25, max: nil, unit: unit, nhsLabel: "Sufficient: 25 nmol/L or above")
        case .tsh:
            LabReferenceRange(min: 0.4, max: 4.0, unit: unit, nhsLabel: "Normal: 0.4–4.0 mIU/L")
        case .bloodPressureSystolic:
            LabReferenceRange(min: nil, max: 140, unit: unit, nhsLabel: "Normal: below 140 mmHg")
        case .bloodPressureDiastolic:
            LabReferenceRange(min: nil, max: 90, unit: unit, nhsLabel: "Normal: below 90 mmHg")
        case .crp:
            LabReferenceRange(min: nil, max: 3.0, unit: unit, nhsLabel: "Low risk: below 3.0 mg/L")
        case .egfr:
            LabReferenceRange(min: 60, max: nil, unit: unit, nhsLabel: "Normal kidney function: 60 or above")
        default:
            nil
        }
    }
}
