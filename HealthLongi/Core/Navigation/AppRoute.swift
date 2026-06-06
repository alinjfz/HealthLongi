import Foundation

enum AppTab: Hashable {
    case dashboard
    case assess
    case trends
    case profile
}

enum AppRoute: Hashable {
    case onboarding
    case questionnaires
    case results(RiskAssessment.ID)
}
