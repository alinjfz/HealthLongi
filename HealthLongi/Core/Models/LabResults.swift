import Foundation

struct LabResults: Codable, Sendable, Equatable {
    // MARK: - Basic: Liver
    var ast: Double?
    var alt: Double?
    var alp: Double?

    // MARK: - Basic: Thyroid
    var ft4: Double?
    var tsh: Double?

    // MARK: - Basic: Inflammation
    var esr: Double?
    var crp: Double?

    // MARK: - Basic: Vitamins
    var vitaminB12: Double?
    var folate: Double?
    var vitaminD: Double?

    // MARK: - Basic: Lipids
    var cholesterol: Double?
    var ldlCholesterol: Double?
    var hdlCholesterol: Double?
    var triglycerides: Double?

    // MARK: - Basic: Metabolic
    var bloodSugar: Double?
    var hba1c: Double?

    // MARK: - Basic: Kidney & BP
    var egfr: Double?
    var creatinine: Double?
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var waistCircumference: Double?

    // MARK: - Extensive: Heart
    var apoB: Double?

    // MARK: - Extensive: Hormones
    var estradiol: Double?
    var progesterone: Double?
    var cortisol: Double?
    var dheas: Double?
    var calcium: Double?

    // MARK: - Extensive: Sleep & minerals
    var magnesium: Double?
    var rbcMagnesium: Double?

    // MARK: - Extensive: CBC differential
    var wbc: Double?
    var neutrophils: Double?
    var lymphocytes: Double?
    var monocytes: Double?
    var eosinophils: Double?
    var basophils: Double?

    // MARK: - Extensive: Recovery / liver extras
    var albumin: Double?
    var ck: Double?
    var ggt: Double?
    var potassium: Double?
    var sodium: Double?

    // MARK: - Extensive: Endurance / hematology
    var ferritin: Double?
    var hematocrit: Double?
    var hemoglobin: Double?
    var iron: Double?
    var tibc: Double?
    var transferrinSaturation: Double?
    var mch: Double?
    var mchc: Double?
    var mcv: Double?
    var rbc: Double?
    var rdw: Double?
    var mpv: Double?
    var platelets: Double?

    // MARK: - Extensive: Fitness hormones
    var testosterone: Double?
    var freeTestosterone: Double?
    var shbg: Double?

    var lastUpdated: Date

    static let empty = LabResults(lastUpdated: .now)

    var hasAnyValue: Bool {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "lastUpdated" { continue }
            if let optional = child.value as? Double?, optional != nil { return true }
            if let optional = child.value as? Int?, optional != nil { return true }
        }
        return false
    }
}
