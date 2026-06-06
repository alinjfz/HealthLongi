import Foundation

@MainActor
@Observable
final class AssessmentHubViewModel {
    private let profile: UserProfile?

    init(profile: UserProfile?) {
        self.profile = profile
    }

    var phq9Completed: Bool { (profile?.phq9Score ?? 0) > 0 }
    var gad7Completed: Bool { (profile?.gad7Score ?? 0) > 0 }
    var metabolicCompleted: Bool {
        profile?.bmi != nil && profile?.physicalActivityMinutes != nil
    }
    var labDataCompleted: Bool { profile?.labResults != nil }
}
