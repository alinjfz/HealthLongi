import Foundation
import SwiftData

@Model
final class UserProfile {
    /// Stored as integer age for SwiftData backward compatibility.
    /// Use `dateOfBirth` for the Date representation.
    var age: Int
    var sexRaw: String
    var smokingStatusRaw: String
    var smokingFrequency: String?
    var genderIdentity: String?
    var createdAt: Date
    var onboardingComplete: Bool

    var phq9Score: Int = 0
    var gad7Score: Int = 0
    var who5Score: Int = 0
    var pss10Score: Int = 0
    var sleepScore: Int = 0
    var auditCScore: Int = 0
    var phq15Score: Int = 0

    var phq9Complete: Bool = false
    var gad7Complete: Bool = false
    var who5Complete: Bool = false
    var pss10Complete: Bool = false
    var sleepComplete: Bool = false
    var auditCComplete: Bool = false
    var phq15Complete: Bool = false

    var phq9CompletedAt: Date?
    var gad7CompletedAt: Date?
    var who5CompletedAt: Date?
    var pss10CompletedAt: Date?
    var sleepCompletedAt: Date?
    var auditCCompletedAt: Date?
    var phq15CompletedAt: Date?

    var bmi: Double?
    var weightKg: Double?
    var heightCm: Double?
    var physicalActivityMinutes: Int?

    @Attribute(.externalStorage) private var manualHealthDataJSON: Data?
    @Attribute(.externalStorage) private var labResultsData: Data?
    @Attribute(.externalStorage) private var labImportHistoryData: Data?
    @Attribute(.externalStorage) private var geneticsProfileData: Data?

    // MARK: - Date of Birth (computed from age)

    var dateOfBirth: Date {
        get { Calendar.current.date(byAdding: .year, value: -age, to: .now) ?? .now }
        set {
            let years = Calendar.current.dateComponents([.year], from: newValue, to: .now).year ?? age
            age = max(0, years)
        }
    }

    // MARK: - Enum Accessors

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .female }
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

    var labImportHistory: [LabImportRecord] {
        get {
            guard let labImportHistoryData else { return [] }
            return (try? JSONDecoder().decode([LabImportRecord].self, from: labImportHistoryData)) ?? []
        }
        set {
            labImportHistoryData = try? JSONEncoder().encode(newValue)
        }
    }

    var manualHealthData: ManualHealthData? {
        get {
            guard let manualHealthDataJSON else { return nil }
            return try? JSONDecoder().decode(ManualHealthData.self, from: manualHealthDataJSON)
        }
        set {
            if let newValue {
                manualHealthDataJSON = try? JSONEncoder().encode(newValue)
            } else {
                manualHealthDataJSON = nil
            }
        }
    }

    var geneticsProfile: GeneticsProfile? {
        get {
            guard let geneticsProfileData else { return nil }
            return try? JSONDecoder().decode(GeneticsProfile.self, from: geneticsProfileData)
        }
        set {
            if let newValue {
                geneticsProfileData = try? JSONEncoder().encode(newValue)
            } else {
                geneticsProfileData = nil
            }
        }
    }

    // MARK: - Init

    init(
        dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now,
        sex: Sex = .female,
        smokingStatus: SmokingStatus = .never,
        smokingFrequency: String? = nil,
        genderIdentity: String? = nil,
        createdAt: Date = .now,
        onboardingComplete: Bool = false,
        phq9Score: Int = 0,
        gad7Score: Int = 0,
        who5Score: Int = 0,
        pss10Score: Int = 0,
        sleepScore: Int = 0,
        auditCScore: Int = 0,
        phq15Score: Int = 0,
        phq9Complete: Bool = false,
        gad7Complete: Bool = false,
        who5Complete: Bool = false,
        pss10Complete: Bool = false,
        sleepComplete: Bool = false,
        auditCComplete: Bool = false,
        phq15Complete: Bool = false,
        bmi: Double? = nil,
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        physicalActivityMinutes: Int? = nil,
        labResults: LabResults? = nil,
        manualHealthData: ManualHealthData? = nil,
        geneticsProfile: GeneticsProfile? = nil
    ) {
        let years = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 30
        self.age = max(0, years)
        self.sexRaw = sex.rawValue
        self.smokingStatusRaw = smokingStatus.rawValue
        self.smokingFrequency = smokingFrequency
        self.genderIdentity = genderIdentity
        self.createdAt = createdAt
        self.onboardingComplete = onboardingComplete
        self.phq9Score = phq9Score
        self.gad7Score = gad7Score
        self.who5Score = who5Score
        self.pss10Score = pss10Score
        self.sleepScore = sleepScore
        self.auditCScore = auditCScore
        self.phq15Score = phq15Score
        self.phq9Complete = phq9Complete
        self.gad7Complete = gad7Complete
        self.who5Complete = who5Complete
        self.pss10Complete = pss10Complete
        self.sleepComplete = sleepComplete
        self.auditCComplete = auditCComplete
        self.phq15Complete = phq15Complete
        self.bmi = bmi
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.physicalActivityMinutes = physicalActivityMinutes
        if let labResults {
            self.labResultsData = try? JSONEncoder().encode(labResults)
        }
        if let manualHealthData {
            self.manualHealthDataJSON = try? JSONEncoder().encode(manualHealthData)
        }
        if let geneticsProfile {
            self.geneticsProfileData = try? JSONEncoder().encode(geneticsProfile)
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

    func markQuestionnaireComplete(_ kind: QuestionnaireKind, score: Int) {
        let now = Date.now
        switch kind {
        case .phq9:
            phq9Score = score
            phq9Complete = true
            phq9CompletedAt = now
        case .gad7:
            gad7Score = score
            gad7Complete = true
            gad7CompletedAt = now
        case .who5:
            who5Score = score
            who5Complete = true
            who5CompletedAt = now
        case .pss10:
            pss10Score = score
            pss10Complete = true
            pss10CompletedAt = now
        case .sleep:
            sleepScore = score
            sleepComplete = true
            sleepCompletedAt = now
        case .auditC:
            auditCScore = score
            auditCComplete = true
            auditCCompletedAt = now
        case .phq15:
            phq15Score = score
            phq15Complete = true
            phq15CompletedAt = now
        }
    }

    func isComplete(_ kind: QuestionnaireKind) -> Bool {
        switch kind {
        case .phq9: phq9Complete
        case .gad7: gad7Complete
        case .who5: who5Complete
        case .pss10: pss10Complete
        case .sleep: sleepComplete
        case .auditC: auditCComplete
        case .phq15: phq15Complete
        }
    }

    func completedAt(_ kind: QuestionnaireKind) -> Date? {
        switch kind {
        case .phq9: phq9CompletedAt
        case .gad7: gad7CompletedAt
        case .who5: who5CompletedAt
        case .pss10: pss10CompletedAt
        case .sleep: sleepCompletedAt
        case .auditC: auditCCompletedAt
        case .phq15: phq15CompletedAt
        }
    }

    /// Syncs metabolic fields from a HealthKit weekly snapshot for risk scoring.
    func syncMetabolicData(from snapshot: WeeklyHealthSnapshot) {
        if let bmi = snapshot.bmi {
            self.bmi = bmi
        }
        if let weightKg = snapshot.bodyMass {
            self.weightKg = weightKg
        }
        if let heightMetres = snapshot.height {
            heightCm = heightMetres * 100
        }
        if let minutes = snapshot.weeklyExerciseMinutes {
            physicalActivityMinutes = minutes
        }
    }

    /// Backfill completion flags for profiles saved before flags were introduced.
    func migrateLegacyQuestionnaireCompletionIfNeeded() {
        let fallbackDate = createdAt
        if !phq9Complete && phq9Score > 0 {
            phq9Complete = true
            phq9CompletedAt = phq9CompletedAt ?? fallbackDate
        }
        if !gad7Complete && gad7Score > 0 {
            gad7Complete = true
            gad7CompletedAt = gad7CompletedAt ?? fallbackDate
        }
    }
}

enum QuestionnaireKind: String, CaseIterable, Identifiable {
    case phq9
    case gad7
    case who5
    case pss10
    case sleep
    case auditC
    case phq15

    var id: String { rawValue }

    /// Questionnaires shown in the Assess hub (excludes deprecated sleep check-in).
    static var activeCases: [QuestionnaireKind] {
        allCases.filter { $0.isActive }
    }

    var isActive: Bool {
        switch self {
        case .sleep: false
        default: true
        }
    }

    var title: String {
        switch self {
        case .phq9: "PHQ-9"
        case .gad7: "GAD-7"
        case .who5: "WHO-5"
        case .pss10: "PSS-10"
        case .sleep: "Sleep Quality Check-in"
        case .auditC: "AUDIT-C"
        case .phq15: "PHQ-15"
        }
    }

    var subtitle: String {
        switch self {
        case .phq9: "Mood check-in (9 questions)"
        case .gad7: "Worry & anxiety check-in (7 questions)"
        case .who5: "Wellbeing index (5 questions)"
        case .pss10: "Stress check-in (10 questions)"
        case .sleep: "Your subjective sleep experience (5 questions)"
        case .auditC: "Alcohol screening (3 questions)"
        case .phq15: "Physical symptoms (15 questions)"
        }
    }

    var icon: String {
        switch self {
        case .phq9: "brain.head.profile"
        case .gad7: "waveform.path.ecg"
        case .who5: "sun.max.fill"
        case .pss10: "bolt.heart.fill"
        case .sleep: "moon.zzz.fill"
        case .auditC: "wineglass.fill"
        case .phq15: "figure.stand"
        }
    }

    var questionCount: Int {
        switch self {
        case .phq9: 9
        case .gad7: 7
        case .who5: 5
        case .pss10: 10
        case .sleep: 5
        case .auditC: 3
        case .phq15: 15
        }
    }

    var intro: String {
        switch self {
        case .phq9, .gad7:
            "Over the last 2 weeks, how often have you felt this way?"
        case .who5:
            "Over the last 2 weeks, how often did you feel this way?"
        case .pss10:
            "In the last month, how often have you felt this way?"
        case .sleep:
            "This asks how you feel about your sleep over the past two weeks. For tracked hours from your watch or phone, see Sleep Duration under HealthKit Data in the Assess tab."
        case .auditC:
            "A few honest questions about alcohol — there are no wrong answers."
        case .phq15:
            "Over the last 4 weeks, how much have these bothered you?"
        }
    }

    var humanizedQuestions: [String] {
        switch self {
        case .phq9: HumanizedQuestions.phq9
        case .gad7: HumanizedQuestions.gad7
        case .who5: HumanizedQuestions.who5
        case .pss10: HumanizedQuestions.pss10
        case .sleep: HumanizedQuestions.sleep
        case .auditC: HumanizedQuestions.auditC
        case .phq15: HumanizedQuestions.phq15
        }
    }

    var likertOptions: [QuestionOption] {
        switch self {
        case .phq9, .gad7, .phq15:
            friendlyFrequencyOptions
        case .who5:
            who5Options
        case .pss10:
            pss10Options
        case .sleep:
            sleepOptions
        case .auditC:
            auditCOptions
        }
    }

    /// Extra context shown above questions in the "About this screening" card.
    var contextSections: [(title: String, body: String)] {
        switch self {
        case .phq9:
            [
                (
                    "What is PHQ-9?",
                    "A 9-question mood screen used in GP surgeries. It helps spot symptoms of depression over the past two weeks."
                ),
                (
                    "How to answer",
                    "Think about how often you have felt this way — not how you think you should feel. There are no wrong answers."
                ),
                (
                    "Your privacy",
                    "Answers stay on your device and are never sent to AI or external services."
                )
            ]
        case .gad7:
            [
                (
                    "What is GAD-7?",
                    "A 7-question anxiety screen used in primary care. It measures worry and nervousness over the past two weeks."
                ),
                (
                    "When to seek help",
                    "Higher scores may suggest it is worth talking to your GP or self-referring to NHS Talking Therapies. This is not a diagnosis."
                ),
                (
                    "Your privacy",
                    "Answers stay on your device and are never sent to AI or external services."
                )
            ]
        case .who5:
            [
                (
                    "What is WHO-5?",
                    "A 5-question wellbeing index from the World Health Organization. It focuses on positive mood and energy."
                ),
                (
                    "How to answer",
                    "Rate how often you felt cheerful, calm, active, and rested over the past two weeks."
                ),
                (
                    "Your privacy",
                    "Answers stay on your device and are never sent to AI or external services."
                )
            ]
        case .pss10:
            [
                (
                    "What is PSS-10?",
                    "The Perceived Stress Scale measures how unpredictable and overwhelming life has felt in the last month."
                ),
                (
                    "Reverse-scored items",
                    "Some questions ask about positive coping (e.g. feeling in control). Those are scored differently — just answer honestly."
                ),
                (
                    "Your privacy",
                    "Answers stay on your device and are never sent to AI or external services."
                )
            ]
        case .sleep:
            []
        case .auditC:
            [
                (
                    "What is AUDIT-C?",
                    "A short 3-question alcohol screen used in GP surgeries. It helps identify drinking patterns that may affect your health."
                ),
                (
                    "What counts as a standard drink?",
                    "In the UK, one unit is about 8g of alcohol — roughly half a pint of beer, a small glass of wine, or a single measure of spirits."
                ),
                (
                    "Your privacy",
                    "Answers stay on your device and are never sent to AI or external services."
                )
            ]
        case .phq15:
            [
                (
                    "What is PHQ-15?",
                    "A 15-question screen for physical symptoms such as pain, fatigue, and digestive issues over the past four weeks."
                ),
                (
                    "How to answer",
                    "Rate how much each symptom has bothered you. It helps connect physical feelings with overall wellbeing."
                ),
                (
                    "Your privacy",
                    "Answers stay on your device and are never sent to AI or external services."
                )
            ]
        }
    }

    var screeningNHSLink: (title: String, url: URL)? {
        switch self {
        case .phq9, .gad7:
            ("NHS mental health support", URL(string: "https://www.nhs.uk/mental-health/")!)
        case .auditC:
            ("NHS alcohol advice", Self.auditCNHSAlcoholURL)
        case .who5, .pss10, .phq15:
            ("NHS Every Mind Matters", URL(string: "https://www.nhs.uk/every-mind-matters/")!)
        case .sleep:
            nil
        }
    }

    /// Per-question footnotes (index → text).
    func questionFooter(at index: Int) -> String? {
        guard self == .auditC, index == 1 else { return nil }
        return "Count UK units: e.g. one pint of beer ≈ 2 units, one large wine glass ≈ 3 units."
    }

    static func auditCScoreInterpretation(for score: Int) -> String {
        switch score {
        case 0...4:
            "Your responses suggest low-risk drinking. Keep within NHS guidance of no more than 14 units per week, spread over several days."
        default:
            "A score of 5 or more can indicate higher-risk drinking. Consider speaking with your GP or visiting NHS alcohol support — this is not a diagnosis."
        }
    }

    static let auditCNHSAlcoholURL = URL(string: "https://www.nhs.uk/live-well/alcohol-advice/")!
}
