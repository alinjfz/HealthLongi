import Foundation

enum BodyRegion: String, CaseIterable, Identifiable {
    case brain
    case heart
    case lungs
    case abdomen
    case leftShoulder
    case rightHip
    case leftKnee

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brain: "Brain"
        case .heart: "Heart"
        case .lungs: "Lungs"
        case .abdomen: "Abdomen"
        case .leftShoulder: "Shoulder"
        case .rightHip: "Hip"
        case .leftKnee: "Knee"
        }
    }

    /// Questionnaires that feed scoring for this body area.
    var relatedQuestionnaires: [QuestionnaireKind] {
        switch self {
        case .brain:
            [.phq9, .gad7, .who5, .pss10]
        case .heart:
            [.pss10]
        case .lungs:
            [.phq15]
        case .abdomen:
            [.auditC]
        case .leftShoulder, .rightHip, .leftKnee:
            [.phq15]
        }
    }

    var assessmentPrompt: String {
        switch self {
        case .brain:
            "Complete mood and wellbeing questionnaires to refine mental-health colouring."
        case .heart:
            "Stress screening helps explain cardiovascular strain alongside HealthKit data."
        case .lungs:
            "Physical symptom screening includes breathing-related items."
        case .abdomen:
            "Alcohol screening contributes to metabolic and liver-related signals."
        case .leftShoulder, .rightHip, .leftKnee:
            "Physical symptom screening covers joint and muscle complaints."
        }
    }
}
