import Foundation

struct NHSLink: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let url: URL
    let description: String
}

enum NHSLinks {
    static let all: [String: NHSLink] = [
        "nhs_talking_therapies": NHSLink(
            id: "nhs_talking_therapies",
            title: "NHS Talking Therapies",
            url: URL(string: "https://www.nhs.uk/nhs-services/mental-health-services/find-nhs-talking-therapies-for-anxiety-and-depression/")!,
            description: "Free NHS psychological therapies for anxiety and depression"
        ),
        "nhs_mental_health": NHSLink(
            id: "nhs_mental_health",
            title: "NHS Mental Health",
            url: URL(string: "https://www.nhs.uk/mental-health/")!,
            description: "Information and support for mental wellbeing"
        ),
        "nhs_active_10": NHSLink(
            id: "nhs_active_10",
            title: "NHS Active 10",
            url: URL(string: "https://www.nhs.uk/live-well/exercise/running-and-aerobic-exercises/get-running-with-couch-to-5k/")!,
            description: "Get active with NHS exercise guidance"
        ),
        "nhs_heart_health": NHSLink(
            id: "nhs_heart_health",
            title: "NHS Heart Health",
            url: URL(string: "https://www.nhs.uk/conditions/coronary-heart-disease/")!,
            description: "Information on cardiovascular health"
        ),
        "nhs_diabetes_prevention": NHSLink(
            id: "nhs_diabetes_prevention",
            title: "NHS Diabetes Prevention",
            url: URL(string: "https://www.nhs.uk/conditions/type-2-diabetes/")!,
            description: "Reduce your risk of type 2 diabetes"
        ),
        "nhs_healthy_weight": NHSLink(
            id: "nhs_healthy_weight",
            title: "NHS Healthy Weight",
            url: URL(string: "https://www.nhs.uk/live-well/healthy-weight/")!,
            description: "Support for maintaining a healthy weight"
        ),
        "nhs_111": NHSLink(
            id: "nhs_111",
            title: "NHS 111 Online",
            url: URL(string: "https://111.nhs.uk/")!,
            description: "Get medical help online"
        ),
        "find_gp": NHSLink(
            id: "find_gp",
            title: "Find a GP",
            url: URL(string: "https://www.nhs.uk/service-search/find-a-gp/")!,
            description: "Find and contact your GP surgery"
        )
    ]

    static func links(for profile: AbstractedRiskProfile) -> [NHSLink] {
        var keys = Set<String>()

        switch profile.mentalHealth {
        case .moderateAnxiety, .highAnxiety, .moderateDepression, .severeDepression:
            keys.insert("nhs_talking_therapies")
            keys.insert("nhs_mental_health")
        case .mild:
            keys.insert("nhs_mental_health")
        case .none:
            break
        }

        switch profile.cardioRisk {
        case .moderate, .high:
            keys.insert("nhs_heart_health")
            keys.insert("nhs_active_10")
        case .low:
            break
        }

        switch profile.metabolic {
        case .moderate, .high:
            keys.insert("nhs_diabetes_prevention")
            keys.insert("nhs_healthy_weight")
        case .low:
            break
        }

        if profile.correlations.contains(where: { $0.contains("steps") }) {
            keys.insert("nhs_active_10")
        }

        return keys.compactMap { all[$0] }
    }

    static func links(forKeys keys: [String]) -> [NHSLink] {
        keys.compactMap { all[$0] }
    }
}
