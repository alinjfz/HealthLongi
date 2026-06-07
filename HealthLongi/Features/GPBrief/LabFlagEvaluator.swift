import Foundation

struct LabFlagEvaluator {
    static func evaluate(labs: LabResults, at date: Date = .now) -> [LabFlag] {
        var flags: [LabFlag] = []

        for biomarker in LabBiomarker.coreReferenceBiomarkers {
            guard let range = biomarker.referenceRange else { continue }

            if biomarker == .bloodPressureSystolic || biomarker == .bloodPressureDiastolic {
                continue
            }

            guard let value = LabBiomarkerIO.doubleValue(biomarker, from: labs) else { continue }

            if let flag = flagIfOutOfRange(biomarker: biomarker, value: value, range: range, at: date) {
                flags.append(flag)
            }
        }

        if let systolic = labs.bloodPressureSystolic,
           let diastolic = labs.bloodPressureDiastolic {
            flags.append(contentsOf: evaluateBloodPressure(
                systolic: systolic,
                diastolic: diastolic,
                at: date
            ))
        }

        return flags.sorted { $0.biomarker.label < $1.biomarker.label }
    }

    private static func evaluateBloodPressure(
        systolic: Int,
        diastolic: Int,
        at date: Date
    ) -> [LabFlag] {
        var flags: [LabFlag] = []
        let sysRange = LabBiomarker.bloodPressureSystolic.referenceRange!
        let diaRange = LabBiomarker.bloodPressureDiastolic.referenceRange!

        if Double(systolic) > sysRange.max ?? .infinity {
            flags.append(LabFlag(
                biomarker: .bloodPressureSystolic,
                value: Double(systolic),
                reference: sysRange,
                direction: .above,
                flaggedAt: date
            ))
        }

        if Double(diastolic) > diaRange.max ?? .infinity {
            flags.append(LabFlag(
                biomarker: .bloodPressureDiastolic,
                value: Double(diastolic),
                reference: diaRange,
                direction: .above,
                flaggedAt: date
            ))
        }

        return flags
    }

    private static func flagIfOutOfRange(
        biomarker: LabBiomarker,
        value: Double,
        range: LabReferenceRange,
        at date: Date
    ) -> LabFlag? {
        if let max = range.max, value > max {
            return LabFlag(
                biomarker: biomarker,
                value: value,
                reference: range,
                direction: .above,
                flaggedAt: date
            )
        }

        if let min = range.min, value < min {
            return LabFlag(
                biomarker: biomarker,
                value: value,
                reference: range,
                direction: .below,
                flaggedAt: date
            )
        }

        return nil
    }
}
