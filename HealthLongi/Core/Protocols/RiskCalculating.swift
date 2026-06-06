import Foundation

protocol RiskCalculating: Sendable {
    func calculate(input: AssessmentInput) -> ScoringResult
}

struct ScoringResult: Sendable, Equatable {
    var profile: AbstractedRiskProfile
    var phq9Score: Int
    var gad7Score: Int
    var metabolicScore: Int
    var cardioScore: Int
}
