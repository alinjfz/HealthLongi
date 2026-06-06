import Foundation

struct MockDNAVariant: Identifiable, Hashable, Sendable {
    let id: String
    let gene: String
    let variant: String
    let category: GeneticsCategory
    let riskLevel: RiskLevel
    let relatedConditions: [String]

    var displayLabel: String { "\(gene) (\(variant))" }
}

enum MockDNAReport {
    static let variants: [MockDNAVariant] = [
        MockDNAVariant(id: "brca1-rs80357906", gene: "BRCA1", variant: "rs80357906", category: .cancer, riskLevel: .high, relatedConditions: ["Hereditary breast and ovarian cancer"]),
        MockDNAVariant(id: "chek2-rs17879961", gene: "CHEK2", variant: "rs17879961", category: .cancer, riskLevel: .moderate, relatedConditions: ["CHEK2-associated cancers"]),
        MockDNAVariant(id: "mlh1-rs1800734", gene: "MLH1", variant: "rs1800734", category: .cancer, riskLevel: .high, relatedConditions: ["Lynch syndrome"]),
        MockDNAVariant(id: "apoe-rs429358", gene: "APOE", variant: "rs429358", category: .neurological, riskLevel: .moderate, relatedConditions: ["Alzheimer's disease (APOE)"]),
        MockDNAVariant(id: "gba-rs421002", gene: "GBA", variant: "rs421002", category: .neurological, riskLevel: .moderate, relatedConditions: ["Parkinson's disease"]),
        MockDNAVariant(id: "myh7-rs1801253", gene: "MYH7", variant: "rs1801253", category: .cardiovascular, riskLevel: .moderate, relatedConditions: ["Hereditary cardiovascular conditions"]),
        MockDNAVariant(id: "pkd1-rs137852918", gene: "PKD1", variant: "rs137852918", category: .kidney, riskLevel: .high, relatedConditions: ["Polycystic kidney disease"]),
        MockDNAVariant(id: "apol1-rs73885319", gene: "APOL1", variant: "rs73885319", category: .kidney, riskLevel: .moderate, relatedConditions: ["APOL1-related kidney disease"]),
        MockDNAVariant(id: "hnf1a-rs1169288", gene: "HNF1A", variant: "rs1169288", category: .metabolic, riskLevel: .moderate, relatedConditions: ["Maturity-onset diabetes of the young"]),
        MockDNAVariant(id: "gla-rs28940893", gene: "GLA", variant: "rs28940893", category: .metabolic, riskLevel: .high, relatedConditions: ["Fabry disease"]),
        MockDNAVariant(id: "tp53-rs28934578", gene: "TP53", variant: "rs28934578", category: .cancer, riskLevel: .high, relatedConditions: ["Li-Fraumeni syndrome"]),
        MockDNAVariant(id: "g6pd-rs1050828", gene: "G6PD", variant: "rs1050828", category: .other, riskLevel: .low, relatedConditions: ["G6PD deficiency"]),
    ]

    static func variants(for ids: [String]) -> [MockDNAVariant] {
        let set = Set(ids)
        return variants.filter { set.contains($0.id) }
    }

    static func defaultUploadSelection() -> [String] {
        variants.map(\.id)
    }

    static func conditions(for variant: MockDNAVariant) -> [GeneticsCondition] {
        GeneticsCatalog.conditions.filter { condition in
            condition.genes.contains(variant.gene)
                || variant.relatedConditions.contains(where: { $0.localizedCaseInsensitiveContains(condition.condition) })
        }
    }

    static func highlightedConditions(for profile: GeneticsProfile) -> [GeneticsCondition] {
        let fromUpload = variants(for: profile.mockVariantIDs).flatMap { conditions(for: $0) }
        let fromFamily = GeneticsCatalog.highlighted(for: profile)
        return Array(Set(fromUpload + fromFamily)).sorted { $0.condition < $1.condition }
    }
}
