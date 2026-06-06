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

    var questionnaire: QuestionnaireKind {
        switch self {
        case .brain: .phq9
        case .heart: .gad7
        case .lungs: .pss10
        case .abdomen: .phq15
        case .leftShoulder, .rightHip, .leftKnee: .phq15
        }
    }
}
