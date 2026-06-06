import Foundation

@MainActor
@Observable
final class AssessmentHubViewModel {
    private let profile: UserProfile?

    init(profile: UserProfile?) {
        self.profile = profile
    }

    var phq9Completed: Bool { profile?.isComplete(.phq9) ?? false }
    var gad7Completed: Bool { profile?.isComplete(.gad7) ?? false }
    var who5Completed: Bool { profile?.isComplete(.who5) ?? false }
    var pss10Completed: Bool { profile?.isComplete(.pss10) ?? false }
    var sleepCompleted: Bool { profile?.isComplete(.sleep) ?? false }
    var auditCCompleted: Bool { profile?.isComplete(.auditC) ?? false }
    var phq15Completed: Bool { profile?.isComplete(.phq15) ?? false }

    var metabolicCompleted: Bool {
        profile?.bmi != nil && profile?.physicalActivityMinutes != nil
    }

    var labDataCompleted: Bool { profile?.labResults != nil }
    var geneticsCompleted: Bool { profile?.geneticsProfile?.quizCompleted == true }
}
