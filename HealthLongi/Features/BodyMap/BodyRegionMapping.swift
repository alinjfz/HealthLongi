import SwiftUI

enum BodyRegionMapping {
    /// Per-organ health colour — each organ uses its own signals where available.
    static func color(
        for organ: AnatomyOrganID,
        profile: AbstractedRiskProfile,
        snapshot: WeeklyHealthSnapshot,
        labResults: LabResults? = nil
    ) -> (color: Color, opacity: Double) {
        switch organ {
        case .brain:
            let c = color(for: BodyRegion.brain, profile: profile, snapshot: snapshot, labResults: labResults)
            return (c, hasBrainSignal(profile: profile, labs: labResults) ? 0.82 : 0.40)
        case .lungs:
            let c = color(for: BodyRegion.lungs, profile: profile, snapshot: snapshot, labResults: labResults)
            return (c, hasLungSignal(profile: profile, snapshot: snapshot, labs: labResults) ? 0.82 : 0.40)
        case .heart:
            let c = color(for: BodyRegion.heart, profile: profile, snapshot: snapshot, labResults: labResults)
            return (c, hasHeartSignal(profile: profile, snapshot: snapshot, labs: labResults) ? 0.82 : 0.40)
        case .liver:
            return liverColor(profile: profile, labs: labResults)
        case .stomach:
            let c = NHSTheme.riskColor(for: profile.metabolic)
            return (c, profile.metabolic != .low || labResults?.hasAnyValue == true ? 0.78 : 0.38)
        case .intestines:
            return intestinesColor(profile: profile, labs: labResults)
        case .kidneys:
            return kidneysColor(labs: labResults)
        case .bladder:
            return (organ.restingTint, 0.32)
        }
    }

    static func color(
        for region: BodyRegion,
        profile: AbstractedRiskProfile,
        snapshot: WeeklyHealthSnapshot,
        labResults: LabResults? = nil
    ) -> Color {
        if let labRisk = labRisk(for: region, labs: labResults) {
            return NHSTheme.riskColor(for: strongestRisk(baseRisk(for: region, profile: profile, snapshot: snapshot), labRisk))
        }

        switch region {
        case .brain:
            return NHSTheme.mentalColor(for: profile.mentalHealth)
        case .heart:
            return NHSTheme.riskColor(for: profile.cardioRisk)
        case .lungs:
            guard let spo2 = snapshot.oxygenSaturation else {
                return NHSTheme.riskColor(for: profile.cardioRisk)
            }
            if spo2 >= 95 { return .green }
            if spo2 >= 90 { return .orange }
            return .red
        case .abdomen:
            return NHSTheme.riskColor(for: profile.metabolic)
        case .leftShoulder, .rightHip, .leftKnee:
            return profile.phq15RiskColor
        }
    }

    private static func baseRisk(for region: BodyRegion, profile: AbstractedRiskProfile, snapshot: WeeklyHealthSnapshot) -> RiskLevel {
        switch region {
        case .brain:
            return riskLevel(for: profile.mentalHealth)
        case .heart:
            return profile.cardioRisk
        case .lungs:
            guard let spo2 = snapshot.oxygenSaturation else { return profile.cardioRisk }
            if spo2 >= 95 { return .low }
            if spo2 >= 90 { return .moderate }
            return .high
        case .abdomen:
            return profile.metabolic
        case .leftShoulder, .rightHip, .leftKnee:
            return riskLevel(for: profile.mentalHealth)
        }
    }

    private static func labRisk(for region: BodyRegion, labs: LabResults?) -> RiskLevel? {
        guard let labs, labs.hasAnyValue else { return nil }

        switch region {
        case .brain:
            return strongestRisk([
                thyroidRisk(tsh: labs.tsh, ft4: labs.ft4),
                lowMarkerRisk(labs.vitaminB12, moderateBelow: 300, highBelow: 200),
                lowMarkerRisk(labs.folate, moderateBelow: 4, highBelow: 3),
                lowMarkerRisk(labs.vitaminD, moderateBelow: 50, highBelow: 30),
                highMarkerRisk(labs.cortisol, moderateAbove: 550, highAbove: 700)
            ])
        case .heart:
            return strongestRisk([
                highMarkerRisk(labs.ldlCholesterol, moderateAbove: 3.0, highAbove: 4.9),
                highMarkerRisk(labs.cholesterol, moderateAbove: 5.0, highAbove: 7.5),
                highMarkerRisk(labs.triglycerides, moderateAbove: 1.7, highAbove: 5.6),
                highMarkerRisk(labs.apoB, moderateAbove: 1.0, highAbove: 1.3),
                bloodPressureRisk(systolic: labs.bloodPressureSystolic, diastolic: labs.bloodPressureDiastolic),
                highMarkerRisk(labs.crp, moderateAbove: 3, highAbove: 10)
            ])
        case .lungs:
            return strongestRisk([
                highMarkerRisk(labs.crp, moderateAbove: 3, highAbove: 10),
                highMarkerRisk(labs.esr, moderateAbove: 20, highAbove: 40)
            ])
        case .abdomen:
            return strongestRisk([
                highMarkerRisk(labs.hba1c, moderateAbove: 42, highAbove: 48),
                highMarkerRisk(labs.bloodSugar, moderateAbove: 7.8, highAbove: 11.1),
                highMarkerRisk(labs.triglycerides, moderateAbove: 1.7, highAbove: 5.6),
                highMarkerRisk(labs.waistCircumference, moderateAbove: 94, highAbove: 102),
                highMarkerRisk(labs.alt, moderateAbove: 45, highAbove: 100),
                highMarkerRisk(labs.ast, moderateAbove: 40, highAbove: 100),
                kidneyRisk(egfr: labs.egfr)
            ])
        case .leftShoulder, .rightHip, .leftKnee:
            return strongestRisk([
                highMarkerRisk(labs.crp, moderateAbove: 3, highAbove: 10),
                highMarkerRisk(labs.esr, moderateAbove: 20, highAbove: 40),
                highMarkerRisk(labs.ck, moderateAbove: 300, highAbove: 1_000),
                lowMarkerRisk(labs.vitaminD, moderateBelow: 50, highBelow: 30)
            ])
        }
    }

    private static func riskLevel(for flag: MentalFlag) -> RiskLevel {
        switch flag {
        case .none, .mild: .low
        case .moderateDepression, .moderateAnxiety: .moderate
        case .severeDepression, .highAnxiety: .high
        }
    }

    private static func strongestRisk(_ first: RiskLevel, _ second: RiskLevel) -> RiskLevel {
        riskValue(first) >= riskValue(second) ? first : second
    }

    private static func strongestRisk(_ risks: [RiskLevel?]) -> RiskLevel? {
        risks.compactMap(\.self).max { riskValue($0) < riskValue($1) }
    }

    private static func riskValue(_ risk: RiskLevel) -> Int {
        switch risk {
        case .low: 0
        case .moderate: 1
        case .high: 2
        }
    }

    private static func highMarkerRisk(_ value: Double?, moderateAbove: Double, highAbove: Double) -> RiskLevel? {
        guard let value else { return nil }
        if value >= highAbove { return .high }
        if value >= moderateAbove { return .moderate }
        return .low
    }

    private static func lowMarkerRisk(_ value: Double?, moderateBelow: Double, highBelow: Double) -> RiskLevel? {
        guard let value else { return nil }
        if value <= highBelow { return .high }
        if value <= moderateBelow { return .moderate }
        return .low
    }

    private static func bloodPressureRisk(systolic: Int?, diastolic: Int?) -> RiskLevel? {
        guard systolic != nil || diastolic != nil else { return nil }
        if (systolic ?? 0) >= 140 || (diastolic ?? 0) >= 90 { return .high }
        if (systolic ?? 0) >= 130 || (diastolic ?? 0) >= 80 { return .moderate }
        return .low
    }

    private static func kidneyRisk(egfr: Double?) -> RiskLevel? {
        guard let egfr else { return nil }
        if egfr < 45 { return .high }
        if egfr < 60 { return .moderate }
        return .low
    }

    private static func thyroidRisk(tsh: Double?, ft4: Double?) -> RiskLevel? {
        if let tsh, tsh < 0.1 || tsh > 10 { return .high }
        if let tsh, tsh < 0.4 || tsh > 4.5 { return .moderate }
        if let ft4, ft4 < 9 || ft4 > 24 { return .moderate }
        guard tsh != nil || ft4 != nil else { return nil }
        return .low
    }

    private static func liverColor(profile: AbstractedRiskProfile, labs: LabResults?) -> (Color, Double) {
        let labRisks = [
            highMarkerRisk(labs?.alt, moderateAbove: 45, highAbove: 100),
            highMarkerRisk(labs?.ast, moderateAbove: 40, highAbove: 100),
            highMarkerRisk(labs?.triglycerides, moderateAbove: 1.7, highAbove: 5.6)
        ]
        if let labRisk = strongestRisk(labRisks) {
            return (NHSTheme.riskColor(for: strongestRisk(profile.metabolic, labRisk)), 0.85)
        }
        if profile.metabolic != .low {
            return (NHSTheme.riskColor(for: profile.metabolic), 0.78)
        }
        return (AnatomyOrganID.liver.restingTint, 0.38)
    }

    private static func intestinesColor(profile: AbstractedRiskProfile, labs: LabResults?) -> (Color, Double) {
        let labRisks = [
            highMarkerRisk(labs?.hba1c, moderateAbove: 42, highAbove: 48),
            highMarkerRisk(labs?.bloodSugar, moderateAbove: 7.8, highAbove: 11.1),
            highMarkerRisk(labs?.triglycerides, moderateAbove: 1.7, highAbove: 5.6)
        ]
        if let labRisk = strongestRisk(labRisks) {
            return (NHSTheme.riskColor(for: strongestRisk(profile.metabolic, labRisk)), 0.85)
        }
        if profile.metabolic != .low {
            return (NHSTheme.riskColor(for: profile.metabolic), 0.78)
        }
        return (AnatomyOrganID.intestines.restingTint, 0.38)
    }

    private static func kidneysColor(labs: LabResults?) -> (Color, Double) {
        guard let egfr = labs?.egfr, let risk = kidneyRisk(egfr: egfr) else {
            return (AnatomyOrganID.kidneys.restingTint, 0.35)
        }
        return (NHSTheme.riskColor(for: risk), 0.85)
    }

    private static func hasBrainSignal(profile: AbstractedRiskProfile, labs: LabResults?) -> Bool {
        profile.mentalHealth != .none && profile.mentalHealth != .mild
            || labs?.tsh != nil || labs?.vitaminD != nil || labs?.vitaminB12 != nil
    }

    private static func hasLungSignal(profile: AbstractedRiskProfile, snapshot: WeeklyHealthSnapshot, labs: LabResults?) -> Bool {
        snapshot.oxygenSaturation != nil || labs?.crp != nil || labs?.esr != nil
            || profile.cardioRisk != .low
    }

    private static func hasHeartSignal(profile: AbstractedRiskProfile, snapshot: WeeklyHealthSnapshot, labs: LabResults?) -> Bool {
        profile.cardioRisk != .low
            || snapshot.averageRestingHeartRate != nil
            || labs?.ldlCholesterol != nil || labs?.bloodPressureSystolic != nil
    }
}

private extension AbstractedRiskProfile {
    var phq15RiskColor: Color {
        switch mentalHealth {
        case .none, .mild: .green
        case .moderateDepression, .moderateAnxiety: .orange
        case .severeDepression, .highAnxiety: .red
        }
    }
}
