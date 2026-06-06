import Foundation

struct LabResults: Codable, Sendable, Equatable {
    // MARK: - Lipids
    var cholesterol: Double?           // Total cholesterol (mmol/L)
    var ldlCholesterol: Double?        // LDL cholesterol (mmol/L)
    var hdlCholesterol: Double?        // HDL cholesterol (mmol/L)
    var triglycerides: Double?         // Triglycerides (mmol/L)

    // MARK: - Blood Pressure
    var bloodPressureSystolic: Int?    // Systolic (mmHg)
    var bloodPressureDiastolic: Int?   // Diastolic (mmHg)

    // MARK: - Glucose & Diabetes
    var bloodSugar: Double?            // Fasting blood sugar (mmol/L)
    var hba1c: Double?                 // HbA1c (%)

    // MARK: - Kidney Function
    var egfr: Double?                  // eGFR (mL/min/1.73m²)
    var creatinine: Double?            // Creatinine (µmol/L)

    // MARK: - Thyroid
    var tsh: Double?                   // TSH (mIU/L)

    // MARK: - Other
    var vitaminD: Double?              // 25-OH Vitamin D (nmol/L)
    var crp: Double?                   // C-Reactive Protein (mg/L)
    var waistCircumference: Double?    // Waist circumference (cm)

    var lastUpdated: Date

    static let empty = LabResults(lastUpdated: .now)
}
