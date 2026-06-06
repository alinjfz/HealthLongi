import Foundation

struct LabReferenceRange: Codable, Sendable, Equatable {
    var min: Double?
    var max: Double?
    var unit: String
    var nhsLabel: String
}

enum LabPanel: String, CaseIterable, Identifiable {
    case basic
    case extensive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: "Basic"
        case .extensive: "Extensive"
        }
    }
}

enum LabCategory: String, CaseIterable, Identifiable {
    case liver
    case thyroid
    case inflammation
    case vitamins
    case lipids
    case metabolic
    case kidneyBP
    case heart
    case hormones
    case sleepMinerals
    case cbc
    case recovery
    case hematology
    case fitnessHormones

    var id: String { rawValue }

    var title: String {
        switch self {
        case .liver: "Liver Function"
        case .thyroid: "Thyroid"
        case .inflammation: "Inflammation"
        case .vitamins: "Vitamins"
        case .lipids: "Lipids"
        case .metabolic: "Glucose & Diabetes"
        case .kidneyBP: "Kidney & Blood Pressure"
        case .heart: "Heart Health"
        case .hormones: "Hormone Balance"
        case .sleepMinerals: "Sleep & Minerals"
        case .cbc: "White Blood Cell Count"
        case .recovery: "Recovery Markers"
        case .hematology: "Endurance & Blood"
        case .fitnessHormones: "Fitness Hormones"
        }
    }

    var panel: LabPanel {
        switch self {
        case .liver, .thyroid, .inflammation, .vitamins, .lipids, .metabolic, .kidneyBP:
            .basic
        default:
            .extensive
        }
    }
}

enum LabBiomarker: String, CaseIterable, Identifiable, Codable {
    case ast, alt, alp
    case ft4, tsh
    case esr, crp
    case vitaminB12, folate, vitaminD
    case cholesterol, ldlCholesterol, hdlCholesterol, triglycerides
    case bloodSugar, hba1c
    case egfr, creatinine, bloodPressureSystolic, bloodPressureDiastolic, waistCircumference
    case apoB
    case estradiol, progesterone, cortisol, dheas, calcium
    case magnesium, rbcMagnesium
    case wbc, neutrophils, lymphocytes, monocytes, eosinophils, basophils
    case albumin, ck, ggt, potassium, sodium
    case ferritin, hematocrit, hemoglobin, iron, tibc, transferrinSaturation
    case mch, mchc, mcv, rbc, rdw, mpv, platelets
    case testosterone, freeTestosterone, shbg

    var id: String { rawValue }

    var category: LabCategory {
        switch self {
        case .ast, .alt, .alp: .liver
        case .ft4, .tsh: .thyroid
        case .esr, .crp: .inflammation
        case .vitaminB12, .folate, .vitaminD: .vitamins
        case .cholesterol, .ldlCholesterol, .hdlCholesterol, .triglycerides: .lipids
        case .bloodSugar, .hba1c: .metabolic
        case .egfr, .creatinine, .bloodPressureSystolic, .bloodPressureDiastolic, .waistCircumference: .kidneyBP
        case .apoB: .heart
        case .estradiol, .progesterone, .cortisol, .dheas, .calcium: .hormones
        case .magnesium, .rbcMagnesium: .sleepMinerals
        case .wbc, .neutrophils, .lymphocytes, .monocytes, .eosinophils, .basophils: .cbc
        case .albumin, .ck, .ggt, .potassium, .sodium: .recovery
        case .ferritin, .hematocrit, .hemoglobin, .iron, .tibc, .transferrinSaturation,
             .mch, .mchc, .mcv, .rbc, .rdw, .mpv, .platelets: .hematology
        case .testosterone, .freeTestosterone, .shbg: .fitnessHormones
        }
    }

    var panel: LabPanel { category.panel }

    var label: String {
        switch self {
        case .ast: "AST"
        case .alt: "ALT"
        case .alp: "ALP"
        case .ft4: "Free T4 (FT4)"
        case .tsh: "TSH"
        case .esr: "ESR"
        case .crp: "hsCRP"
        case .vitaminB12: "Vitamin B12"
        case .folate: "Folate"
        case .vitaminD: "Vitamin D"
        case .cholesterol: "Total cholesterol"
        case .ldlCholesterol: "LDL cholesterol"
        case .hdlCholesterol: "HDL cholesterol"
        case .triglycerides: "Triglycerides"
        case .bloodSugar: "Fasting glucose"
        case .hba1c: "HbA1c"
        case .egfr: "eGFR"
        case .creatinine: "Creatinine"
        case .bloodPressureSystolic: "Systolic BP"
        case .bloodPressureDiastolic: "Diastolic BP"
        case .waistCircumference: "Waist circumference"
        case .apoB: "Apolipoprotein B"
        case .estradiol: "Estradiol"
        case .progesterone: "Progesterone"
        case .cortisol: "Cortisol"
        case .dheas: "DHEAS"
        case .calcium: "Calcium"
        case .magnesium: "Magnesium"
        case .rbcMagnesium: "RBC magnesium"
        case .wbc: "White blood cells"
        case .neutrophils: "Neutrophils"
        case .lymphocytes: "Lymphocytes"
        case .monocytes: "Monocytes"
        case .eosinophils: "Eosinophils"
        case .basophils: "Basophils"
        case .albumin: "Albumin"
        case .ck: "Creatine kinase"
        case .ggt: "GGT"
        case .potassium: "Potassium"
        case .sodium: "Sodium"
        case .ferritin: "Ferritin"
        case .hematocrit: "Haematocrit"
        case .hemoglobin: "Haemoglobin"
        case .iron: "Iron"
        case .tibc: "TIBC"
        case .transferrinSaturation: "Transferrin saturation"
        case .mch: "MCH"
        case .mchc: "MCHC"
        case .mcv: "MCV"
        case .rbc: "Red blood cell count"
        case .rdw: "RDW"
        case .mpv: "Mean platelet volume"
        case .platelets: "Platelets"
        case .testosterone: "Testosterone"
        case .freeTestosterone: "Free testosterone"
        case .shbg: "SHBG"
        }
    }

    var unit: String {
        switch self {
        case .ast, .alt, .alp, .albumin, .ck, .ggt, .vitaminB12, .folate, .creatinine, .iron, .magnesium, .rbcMagnesium, .calcium, .potassium, .sodium, .ferritin, .testosterone, .freeTestosterone, .shbg, .estradiol, .progesterone, .cortisol, .dheas, .apoB:
            "µmol/L"
        case .ft4: "pmol/L"
        case .tsh: "mIU/L"
        case .esr: "mm/hr"
        case .crp: "mg/L"
        case .vitaminD: "nmol/L"
        case .cholesterol, .ldlCholesterol, .hdlCholesterol, .triglycerides, .bloodSugar:
            "mmol/L"
        case .hba1c: "%"
        case .egfr: "mL/min/1.73m²"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "mmHg"
        case .waistCircumference: "cm"
        case .wbc, .neutrophils, .lymphocytes, .monocytes, .eosinophils, .basophils, .rbc, .platelets:
            "×10⁹/L"
        case .hematocrit, .transferrinSaturation: "%"
        case .hemoglobin: "g/L"
        case .tibc: "µmol/L"
        case .mch, .mcv, .mpv: "fL"
        case .mchc: "g/L"
        case .rdw: "%"
        }
    }

    var hint: String {
        switch self {
        case .cholesterol: "NHS: below 5.0 mmol/L is desirable"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "Normal: below 120/80 mmHg"
        case .bloodSugar: "Normal fasting: 3.9–5.5 mmol/L"
        case .hba1c: "Non-diabetic: below 6.0%"
        case .vitaminD: "Deficient: below 25 nmol/L"
        case .tsh: "Normal: 0.4–4.0 mIU/L"
        default: "Enter your latest lab value if known"
        }
    }

    var sexFilter: Sex? {
        switch self {
        case .estradiol, .progesterone, .dheas: .female
        case .freeTestosterone: .male
        default: nil
        }
    }

    var isIntegerField: Bool {
        switch self {
        case .bloodPressureSystolic, .bloodPressureDiastolic: true
        default: false
        }
    }

    /// OCR aliases for on-device report parsing
    var ocrAliases: [String] {
        var aliases = [label, rawValue.uppercased(), label.replacingOccurrences(of: " ", with: "")]
        switch self {
        case .hemoglobin: aliases += ["Haemoglobin", "Hemoglobin", "HGB"]
        case .hematocrit: aliases += ["Haematocrit", "HCT"]
        case .hba1c: aliases += ["HbA1c", "Hb A1c", "Glycated haemoglobin"]
        case .ldlCholesterol: aliases += ["LDL Cholesterol", "LDL"]
        case .hdlCholesterol: aliases += ["HDL Cholesterol", "HDL"]
        case .cholesterol: aliases += ["Total Cholesterol", "Cholesterol"]
        case .triglycerides: aliases += ["Triglyceride"]
        case .creatinine: aliases += ["Creat"]
        case .egfr: aliases += ["eGFR (CKD-EPI)", "eGFR", "GFR"]
        case .alt: aliases += ["Alanine aminotransferase"]
        case .ast: aliases += ["Aspartate aminotransferase"]
        case .alp: aliases += ["Alkaline phosphatase"]
        case .ggt: aliases += ["Gamma-glutamyl"]
        case .tsh: aliases += ["Thyroid-stimulating hormone"]
        case .ft4: aliases += ["Free T4", "Thyroxine"]
        case .wbc: aliases += ["White Cell Count", "WBC"]
        case .platelets: aliases += ["Platelet"]
        case .sodium: aliases += ["Na"]
        case .potassium: aliases += ["K"]
        case .albumin: aliases += ["Serum albumin"]
        case .crp: aliases += ["C-reactive protein", "hsCRP", "CRP"]
        default: break
        }
        return aliases
    }

    static func forPanel(_ panel: LabPanel, sex: Sex) -> [LabCategory: [LabBiomarker]] {
        var grouped: [LabCategory: [LabBiomarker]] = [:]
        for marker in allCases where marker.panel == panel {
            if let filter = marker.sexFilter, filter != sex { continue }
            grouped[marker.category, default: []].append(marker)
        }
        return grouped
    }

    static let coreReferenceBiomarkers: [LabBiomarker] = [
        .hba1c, .ldlCholesterol, .hdlCholesterol, .cholesterol, .bloodSugar,
        .vitaminD, .tsh, .bloodPressureSystolic, .bloodPressureDiastolic,
        .crp, .egfr
    ]

    var referenceRange: LabReferenceRange? {
        switch self {
        case .hba1c:
            LabReferenceRange(min: nil, max: 6.0, unit: unit, nhsLabel: "Non-diabetic: below 6.0%")
        case .ldlCholesterol:
            LabReferenceRange(min: nil, max: 3.0, unit: unit, nhsLabel: "Desirable: below 3.0 mmol/L")
        case .hdlCholesterol:
            LabReferenceRange(min: 1.0, max: nil, unit: unit, nhsLabel: "Desirable: 1.0 mmol/L or above")
        case .cholesterol:
            LabReferenceRange(min: nil, max: 5.0, unit: unit, nhsLabel: "Desirable: below 5.0 mmol/L")
        case .bloodSugar:
            LabReferenceRange(min: 3.9, max: 5.5, unit: unit, nhsLabel: "Normal fasting: 3.9–5.5 mmol/L")
        case .vitaminD:
            LabReferenceRange(min: 25, max: nil, unit: unit, nhsLabel: "Sufficient: 25 nmol/L or above")
        case .tsh:
            LabReferenceRange(min: 0.4, max: 4.0, unit: unit, nhsLabel: "Normal: 0.4–4.0 mIU/L")
        case .bloodPressureSystolic:
            LabReferenceRange(min: nil, max: 140, unit: unit, nhsLabel: "Normal: below 140 mmHg")
        case .bloodPressureDiastolic:
            LabReferenceRange(min: nil, max: 90, unit: unit, nhsLabel: "Normal: below 90 mmHg")
        case .crp:
            LabReferenceRange(min: nil, max: 3.0, unit: unit, nhsLabel: "Low risk: below 3.0 mg/L")
        case .egfr:
            LabReferenceRange(min: 60, max: nil, unit: unit, nhsLabel: "Normal kidney function: 60 or above")
        default:
            nil
        }
    }
}

struct LabBiomarkerIO {
    static func stringValue(_ marker: LabBiomarker, from labs: LabResults) -> String? {
        guard let value = doubleValue(marker, from: labs) else {
            if marker.isIntegerField, let intVal = intValue(marker, from: labs) {
                return "\(intVal)"
            }
            return nil
        }
        return format(value)
    }

    static func doubleValue(_ marker: LabBiomarker, from labs: LabResults) -> Double? {
        switch marker {
        case .ast: labs.ast
        case .alt: labs.alt
        case .alp: labs.alp
        case .ft4: labs.ft4
        case .tsh: labs.tsh
        case .esr: labs.esr
        case .crp: labs.crp
        case .vitaminB12: labs.vitaminB12
        case .folate: labs.folate
        case .vitaminD: labs.vitaminD
        case .cholesterol: labs.cholesterol
        case .ldlCholesterol: labs.ldlCholesterol
        case .hdlCholesterol: labs.hdlCholesterol
        case .triglycerides: labs.triglycerides
        case .bloodSugar: labs.bloodSugar
        case .hba1c: labs.hba1c
        case .egfr: labs.egfr
        case .creatinine: labs.creatinine
        case .bloodPressureSystolic: labs.bloodPressureSystolic.map(Double.init)
        case .bloodPressureDiastolic: labs.bloodPressureDiastolic.map(Double.init)
        case .waistCircumference: labs.waistCircumference
        case .apoB: labs.apoB
        case .estradiol: labs.estradiol
        case .progesterone: labs.progesterone
        case .cortisol: labs.cortisol
        case .dheas: labs.dheas
        case .calcium: labs.calcium
        case .magnesium: labs.magnesium
        case .rbcMagnesium: labs.rbcMagnesium
        case .wbc: labs.wbc
        case .neutrophils: labs.neutrophils
        case .lymphocytes: labs.lymphocytes
        case .monocytes: labs.monocytes
        case .eosinophils: labs.eosinophils
        case .basophils: labs.basophils
        case .albumin: labs.albumin
        case .ck: labs.ck
        case .ggt: labs.ggt
        case .potassium: labs.potassium
        case .sodium: labs.sodium
        case .ferritin: labs.ferritin
        case .hematocrit: labs.hematocrit
        case .hemoglobin: labs.hemoglobin
        case .iron: labs.iron
        case .tibc: labs.tibc
        case .transferrinSaturation: labs.transferrinSaturation
        case .mch: labs.mch
        case .mchc: labs.mchc
        case .mcv: labs.mcv
        case .rbc: labs.rbc
        case .rdw: labs.rdw
        case .mpv: labs.mpv
        case .platelets: labs.platelets
        case .testosterone: labs.testosterone
        case .freeTestosterone: labs.freeTestosterone
        case .shbg: labs.shbg
        }
    }

    static func intValue(_ marker: LabBiomarker, from labs: LabResults) -> Int? {
        switch marker {
        case .bloodPressureSystolic: labs.bloodPressureSystolic
        case .bloodPressureDiastolic: labs.bloodPressureDiastolic
        default: nil
        }
    }

    static func setValue(_ marker: LabBiomarker, value: Double?, on labs: inout LabResults) {
        switch marker {
        case .ast: labs.ast = value
        case .alt: labs.alt = value
        case .alp: labs.alp = value
        case .ft4: labs.ft4 = value
        case .tsh: labs.tsh = value
        case .esr: labs.esr = value
        case .crp: labs.crp = value
        case .vitaminB12: labs.vitaminB12 = value
        case .folate: labs.folate = value
        case .vitaminD: labs.vitaminD = value
        case .cholesterol: labs.cholesterol = value
        case .ldlCholesterol: labs.ldlCholesterol = value
        case .hdlCholesterol: labs.hdlCholesterol = value
        case .triglycerides: labs.triglycerides = value
        case .bloodSugar: labs.bloodSugar = value
        case .hba1c: labs.hba1c = value
        case .egfr: labs.egfr = value
        case .creatinine: labs.creatinine = value
        case .bloodPressureSystolic: labs.bloodPressureSystolic = value.map { Int($0) }
        case .bloodPressureDiastolic: labs.bloodPressureDiastolic = value.map { Int($0) }
        case .waistCircumference: labs.waistCircumference = value
        case .apoB: labs.apoB = value
        case .estradiol: labs.estradiol = value
        case .progesterone: labs.progesterone = value
        case .cortisol: labs.cortisol = value
        case .dheas: labs.dheas = value
        case .calcium: labs.calcium = value
        case .magnesium: labs.magnesium = value
        case .rbcMagnesium: labs.rbcMagnesium = value
        case .wbc: labs.wbc = value
        case .neutrophils: labs.neutrophils = value
        case .lymphocytes: labs.lymphocytes = value
        case .monocytes: labs.monocytes = value
        case .eosinophils: labs.eosinophils = value
        case .basophils: labs.basophils = value
        case .albumin: labs.albumin = value
        case .ck: labs.ck = value
        case .ggt: labs.ggt = value
        case .potassium: labs.potassium = value
        case .sodium: labs.sodium = value
        case .ferritin: labs.ferritin = value
        case .hematocrit: labs.hematocrit = value
        case .hemoglobin: labs.hemoglobin = value
        case .iron: labs.iron = value
        case .tibc: labs.tibc = value
        case .transferrinSaturation: labs.transferrinSaturation = value
        case .mch: labs.mch = value
        case .mchc: labs.mchc = value
        case .mcv: labs.mcv = value
        case .rbc: labs.rbc = value
        case .rdw: labs.rdw = value
        case .mpv: labs.mpv = value
        case .platelets: labs.platelets = value
        case .testosterone: labs.testosterone = value
        case .freeTestosterone: labs.freeTestosterone = value
        case .shbg: labs.shbg = value
        }
    }

    private static func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
