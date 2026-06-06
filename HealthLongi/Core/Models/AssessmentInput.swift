import Foundation

struct AssessmentInput: Sendable, Equatable {
    var demographics: Demographics
    var weeklySteps: Int?
    var priorWeeklySteps: Int?
    var restingHeartRate: Double?
    var sleepHoursAvg: Double?
    var phq9Score: Int
    var gad7Score: Int
    var bmi: Double?
    var physicalActivityMinutes: Int?
    var labSignals: LabRiskSignals = .empty
    var who5Score: Int?
    var pss10Score: Int?
    var phq15Score: Int?
    var auditCScore: Int?
}
