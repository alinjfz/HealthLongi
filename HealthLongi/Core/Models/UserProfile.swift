import Foundation
import SwiftData

@Model
final class UserProfile {
    var age: Int
    var sexRaw: String
    var smokingStatusRaw: String
    var smokingFrequency: String?
    var genderIdentity: String?
    var createdAt: Date
    var onboardingComplete: Bool

    var phq9Score: Int
    var gad7Score: Int
    var bmi: Double?
    var physicalActivityMinutes: Int?

    @Attribute(.externalStorage) private var labResultsData: Data?

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .other }
        set { sexRaw = newValue.rawValue }
    }

    var smokingStatus: SmokingStatus {
        get { SmokingStatus.fromStored(smokingStatusRaw) }
        set { smokingStatusRaw = newValue.rawValue }
    }

    var labResults: LabResults? {
        get {
            guard let labResultsData else { return nil }
            return try? JSONDecoder().decode(LabResults.self, from: labResultsData)
        }
        set {
            if let newValue {
                labResultsData = try? JSONEncoder().encode(newValue)
            } else {
                labResultsData = nil
            }
        }
    }

    init(
        age: Int = 30,
        sex: Sex = .other,
        smokingStatus: SmokingStatus = .never,
        smokingFrequency: String? = nil,
        genderIdentity: String? = nil,
        createdAt: Date = .now,
        onboardingComplete: Bool = false,
        phq9Score: Int = 0,
        gad7Score: Int = 0,
        bmi: Double? = nil,
        physicalActivityMinutes: Int? = nil,
        labResults: LabResults? = nil
    ) {
        self.age = age
        self.sexRaw = sex.rawValue
        self.smokingStatusRaw = smokingStatus.rawValue
        self.smokingFrequency = smokingFrequency
        self.genderIdentity = genderIdentity
        self.createdAt = createdAt
        self.onboardingComplete = onboardingComplete
        self.phq9Score = phq9Score
        self.gad7Score = gad7Score
        self.bmi = bmi
        self.physicalActivityMinutes = physicalActivityMinutes
        if let labResults {
            self.labResultsData = try? JSONEncoder().encode(labResults)
        }
    }

    var demographics: Demographics {
        Demographics(
            age: age,
            sex: sex,
            smokingStatus: smokingStatus,
            smokingFrequency: smokingFrequency,
            genderIdentity: genderIdentity
        )
    }
}
