import Foundation
import SwiftData

enum DemoSeeder {
    /// Seeds demo profile and questionnaire data for pitch rehearsals.
    @MainActor
    static func seedDemoProfile(context: ModelContext) {
        let profile: UserProfile
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            profile = existing
        } else {
            profile = UserProfile()
            context.insert(profile)
        }

        profile.age = 32
        profile.sex = .female
        profile.smokingStatus = .never
        profile.onboardingComplete = true
        profile.phq9Score = 8
        profile.gad7Score = 14
        profile.bmi = 24.5
        profile.physicalActivityMinutes = 20

        try? context.save()
    }
}
