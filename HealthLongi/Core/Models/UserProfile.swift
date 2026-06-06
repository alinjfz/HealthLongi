import Foundation
import SwiftData

@Model
final class UserProfile {
    var age: Int
    var sexRaw: String
    var smokingStatusRaw: String
    var createdAt: Date
    var onboardingComplete: Bool

    var phq9Score: Int
    var gad7Score: Int
    var bmi: Double?
    var physicalActivityMinutes: Int?

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .other }
        set { sexRaw = newValue.rawValue }
    }

    var smokingStatus: SmokingStatus {
        get { SmokingStatus(rawValue: smokingStatusRaw) ?? .never }
        set { smokingStatusRaw = newValue.rawValue }
    }

    init(
        age: Int = 30,
        sex: Sex = .other,
        smokingStatus: SmokingStatus = .never,
        createdAt: Date = .now,
        onboardingComplete: Bool = false,
        phq9Score: Int = 0,
        gad7Score: Int = 0,
        bmi: Double? = nil,
        physicalActivityMinutes: Int? = nil
    ) {
        self.age = age
        self.sexRaw = sex.rawValue
        self.smokingStatusRaw = smokingStatus.rawValue
        self.createdAt = createdAt
        self.onboardingComplete = onboardingComplete
        self.phq9Score = phq9Score
        self.gad7Score = gad7Score
        self.bmi = bmi
        self.physicalActivityMinutes = physicalActivityMinutes
    }

    var demographics: Demographics {
        Demographics(age: age, sex: sex, smokingStatus: smokingStatus)
    }
}
