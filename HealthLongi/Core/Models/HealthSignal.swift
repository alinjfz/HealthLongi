import Foundation

struct EvidenceItem: Codable, Sendable, Equatable, Identifiable {
    enum Source: String, Codable, Sendable {
        case screening
        case healthKit
        case lab
        case lifestyle
    }

    var id: String
    var source: Source
    var label: String
    var value: String
    var detail: String?

    init(id: String = UUID().uuidString, source: Source, label: String, value: String, detail: String? = nil) {
        self.id = id
        self.source = source
        self.label = label
        self.value = value
        self.detail = detail
    }
}

struct HealthSignal: Identifiable, Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable {
        case correlation
        case trend
        case screening
        case labFlag
        case lifestyle
    }

    enum Severity: String, Codable, Sendable, Comparable {
        case info
        case watch
        case discussWithGP

        private var sortOrder: Int {
            switch self {
            case .discussWithGP: 0
            case .watch: 1
            case .info: 2
            }
        }

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }
    }

    var id: String
    var kind: Kind
    var title: String
    var detail: String
    var evidence: [EvidenceItem]
    var suggestedQuestions: [String]
    var severity: Severity
    var bodyRegion: BodyRegion?
    var createdAt: Date
}

struct SignalEngineInput: Sendable, Equatable {
    var phq9Score: Int
    var gad7Score: Int
    var who5Score: Int
    var pss10Score: Int
    var auditCScore: Int
    var phq15Score: Int
    var bmi: Double?
    var snapshot: WeeklyHealthSnapshot
    var priorSnapshot: WeeklyHealthSnapshot?
    var labFlags: [LabFlag]
    var labResults: LabResults?
    var priorRestingHeartRate: Double?

    static func from(profile: UserProfile, snapshot: WeeklyHealthSnapshot, labFlags: [LabFlag]) -> SignalEngineInput {
        SignalEngineInput(
            phq9Score: profile.phq9Score,
            gad7Score: profile.gad7Score,
            who5Score: profile.who5Score,
            pss10Score: profile.pss10Score,
            auditCScore: profile.auditCScore,
            phq15Score: profile.phq15Score,
            bmi: profile.bmi ?? snapshot.bmi,
            snapshot: snapshot,
            priorSnapshot: nil,
            labFlags: labFlags,
            labResults: profile.labResults,
            priorRestingHeartRate: snapshot.priorAverageRestingHeartRate
        )
    }

    static let empty = SignalEngineInput(
        phq9Score: 0,
        gad7Score: 0,
        who5Score: 0,
        pss10Score: 0,
        auditCScore: 0,
        phq15Score: 0,
        bmi: nil,
        snapshot: .empty,
        priorSnapshot: nil,
        labFlags: [],
        labResults: nil,
        priorRestingHeartRate: nil
    )
}
