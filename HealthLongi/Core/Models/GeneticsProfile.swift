import Foundation

struct GeneticsProfile: Codable, Sendable, Equatable {
    var quizCompleted: Bool
    var quizCompletedAt: Date?
    var familyCancer: Bool
    var familyHeart: Bool
    var familyKidney: Bool
    var familyNeuro: Bool
    var familyMetabolic: Bool
    var familyBreastOvarian: Bool
    var familyColon: Bool
    var familyDiabetes: Bool
    var reportViewed: Bool

    static let empty = GeneticsProfile(
        quizCompleted: false,
        familyCancer: false,
        familyHeart: false,
        familyKidney: false,
        familyNeuro: false,
        familyMetabolic: false,
        familyBreastOvarian: false,
        familyColon: false,
        familyDiabetes: false,
        reportViewed: false
    )
}

struct GeneticsCondition: Identifiable, Hashable {
    let id: String
    let condition: String
    let genes: [String]
    let category: GeneticsCategory
    let summary: String
}

enum GeneticsCategory: String, CaseIterable, Identifiable {
    case cancer
    case cardiovascular
    case metabolic
    case kidney
    case neurological
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cancer: "Hereditary Cancer"
        case .cardiovascular: "Cardiovascular Disease"
        case .metabolic: "Metabolic Conditions"
        case .kidney: "Kidney Disease"
        case .neurological: "Neurological Conditions"
        case .other: "Other Hereditary Conditions"
        }
    }
}

enum GeneticsCatalog {
    static let conditions: [GeneticsCondition] = [
        GeneticsCondition(id: "brca", condition: "Hereditary breast and ovarian cancer", genes: ["BRCA1", "BRCA2"], category: .cancer, summary: "Inherited changes in BRCA genes can increase lifetime risk of breast and ovarian cancer."),
        GeneticsCondition(id: "lynch", condition: "Lynch syndrome", genes: ["MLH1", "MSH2", "MSH6", "PMS2"], category: .cancer, summary: "Raises risk of colorectal and other cancers; NHS offers screening for affected families."),
        GeneticsCondition(id: "apoe", condition: "Alzheimer's disease (APOE)", genes: ["APOE"], category: .neurological, summary: "APOE variants influence late-onset Alzheimer's risk — one factor among many, not a diagnosis."),
        GeneticsCondition(id: "parkinsons", condition: "Parkinson's disease", genes: ["GBA", "LRRK2"], category: .neurological, summary: "Some inherited gene changes are linked to higher Parkinson's risk."),
        GeneticsCondition(id: "pkd", condition: "Polycystic kidney disease", genes: ["PKD1", "PKD2"], category: .kidney, summary: "Causes cysts in the kidneys and can affect kidney function over time."),
        GeneticsCondition(id: "apol1", condition: "APOL1-related kidney disease", genes: ["APOL1"], category: .kidney, summary: "Associated with higher risk of chronic kidney disease in some populations."),
        GeneticsCondition(id: "hcm", condition: "Hereditary cardiovascular conditions", genes: ["MYH7", "MYBPC3"], category: .cardiovascular, summary: "Family history of early heart disease may warrant GP discussion and monitoring."),
        GeneticsCondition(id: "mod", condition: "Maturity-onset diabetes of the young", genes: ["HNF1A"], category: .metabolic, summary: "A rare inherited form of diabetes often diagnosed before age 25."),
        GeneticsCondition(id: "fabry", condition: "Fabry disease", genes: ["GLA"], category: .metabolic, summary: "A rare inherited disorder affecting heart, kidneys, and nerves."),
        GeneticsCondition(id: "tp53", condition: "Li-Fraumeni syndrome", genes: ["TP53"], category: .cancer, summary: "Greatly increases risk of several cancers across the lifespan."),
        GeneticsCondition(id: "chek2", condition: "CHEK2-associated cancers", genes: ["CHEK2"], category: .cancer, summary: "Moderately increases breast and other cancer risks."),
        GeneticsCondition(id: "g6pd", condition: "G6PD deficiency", genes: ["G6PD"], category: .other, summary: "Can cause reactions to certain foods and medicines."),
    ]

    static func highlighted(for profile: GeneticsProfile) -> [GeneticsCondition] {
        var results: [GeneticsCondition] = []
        if profile.familyBreastOvarian {
            results.append(contentsOf: conditions.filter { $0.id == "brca" || $0.id == "chek2" })
        }
        if profile.familyColon || profile.familyCancer {
            results.append(contentsOf: conditions.filter { $0.id == "lynch" || $0.id == "tp53" })
        }
        if profile.familyNeuro {
            results.append(contentsOf: conditions.filter { $0.category == .neurological })
        }
        if profile.familyKidney {
            results.append(contentsOf: conditions.filter { $0.category == .kidney })
        }
        if profile.familyHeart {
            results.append(contentsOf: conditions.filter { $0.category == .cardiovascular })
        }
        if profile.familyMetabolic || profile.familyDiabetes {
            results.append(contentsOf: conditions.filter { $0.category == .metabolic })
        }
        if results.isEmpty {
            return Array(conditions.prefix(3))
        }
        return Array(Set(results)).sorted { $0.condition < $1.condition }
    }
}
