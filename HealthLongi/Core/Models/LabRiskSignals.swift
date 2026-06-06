import Foundation

/// Anonymized lab-derived flags for on-device scoring and AI context.
/// Never contains raw biomarker values.
struct LabRiskSignals: Codable, Sendable, Equatable {
    var elevatedLipids: Bool = false
    var elevatedGlucose: Bool = false
    var elevatedBloodPressure: Bool = false
    var elevatedInflammation: Bool = false
    var elevatedWaist: Bool = false
    var kidneyConcern: Bool = false
    var thyroidConcern: Bool = false
    var lowVitamins: Bool = false

    static let empty = LabRiskSignals()

    var hasAnySignal: Bool {
        elevatedLipids || elevatedGlucose || elevatedBloodPressure || elevatedInflammation
            || elevatedWaist || kidneyConcern || thyroidConcern || lowVitamins
    }

    static func from(labs: LabResults?) -> LabRiskSignals {
        guard let labs, labs.hasAnyValue else { return .empty }

        var signals = LabRiskSignals()

        if markerHigh(labs.ldlCholesterol, moderate: 3.0, high: 4.9)
            || markerHigh(labs.cholesterol, moderate: 5.0, high: 7.5)
            || markerHigh(labs.triglycerides, moderate: 1.7, high: 5.6)
            || markerHigh(labs.apoB, moderate: 1.0, high: 1.3) {
            signals.elevatedLipids = true
        }

        if markerHigh(labs.hba1c, moderate: 5.7, high: 6.5)
            || markerHigh(labs.bloodSugar, moderate: 7.8, high: 11.1) {
            signals.elevatedGlucose = true
        }

        if (labs.bloodPressureSystolic ?? 0) >= 130 || (labs.bloodPressureDiastolic ?? 0) >= 80 {
            signals.elevatedBloodPressure = true
        }

        if markerHigh(labs.crp, moderate: 3, high: 10) || markerHigh(labs.esr, moderate: 20, high: 40) {
            signals.elevatedInflammation = true
        }

        if markerHigh(labs.waistCircumference, moderate: 94, high: 102) {
            signals.elevatedWaist = true
        }

        if let egfr = labs.egfr, egfr < 60 {
            signals.kidneyConcern = true
        }

        if let tsh = labs.tsh, tsh < 0.4 || tsh > 4.5 {
            signals.thyroidConcern = true
        } else if let ft4 = labs.ft4, ft4 < 9 || ft4 > 24 {
            signals.thyroidConcern = true
        }

        if markerLow(labs.vitaminB12, moderate: 300, high: 200)
            || markerLow(labs.folate, moderate: 4, high: 3)
            || markerLow(labs.vitaminD, moderate: 50, high: 30) {
            signals.lowVitamins = true
        }

        return signals
    }

    private static func markerHigh(_ value: Double?, moderate: Double, high: Double) -> Bool {
        guard let value else { return false }
        return value >= moderate
    }

    private static func markerLow(_ value: Double?, moderate: Double, high: Double) -> Bool {
        guard let value else { return false }
        return value <= moderate
    }
}
