import Foundation

struct HealthTip: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: HealthCategory

    init(title: String, description: String, icon: String, category: HealthCategory) {
        self.id = title.lowercased().replacingOccurrences(of: " ", with: "_")
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
    }
}

enum HealthTips {
    static let all: [HealthTip] = [
        HealthTip(
            title: "Morning Stretch",
            description: "Start your day with 5 minutes of stretching to improve flexibility and circulation.",
            icon: "figure.flexibility",
            category: .activity
        ),
        HealthTip(
            title: "Mindful Breathing",
            description: "Practice 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s.",
            icon: "wind",
            category: .mental
        ),
        HealthTip(
            title: "Stay Hydrated",
            description: "Drink a glass of water before each meal to support digestion and energy.",
            icon: "drop.fill",
            category: .general
        ),
        HealthTip(
            title: "Evening Wind-Down",
            description: "Avoid screens 1 hour before bed to improve sleep quality.",
            icon: "moon.fill",
            category: .sleep
        ),
        HealthTip(
            title: "Heart-Healthy Walk",
            description: "A brisk 10-minute walk after meals can support cardiovascular health.",
            icon: "heart.fill",
            category: .physical
        ),
        HealthTip(
            title: "Mood Check-In",
            description: "Take a moment each day to notice how you feel without judgement.",
            icon: "brain.head.profile",
            category: .mental
        )
    ]

    static func forProfile(_ profile: AbstractedRiskProfile) -> [HealthTip] {
        var tips: [HealthTip] = []

        switch profile.mentalHealth {
        case .moderateAnxiety, .highAnxiety, .moderateDepression, .severeDepression, .mild:
            tips.append(contentsOf: all.filter { $0.category == .mental })
        case .none:
            break
        }

        switch profile.cardioRisk {
        case .moderate, .high:
            tips.append(contentsOf: all.filter { $0.category == .physical || $0.category == .activity })
        case .low:
            break
        }

        switch profile.metabolic {
        case .moderate, .high:
            tips.append(contentsOf: all.filter { $0.title == "Morning Stretch" || $0.title == "Stay Hydrated" })
        case .low:
            break
        }

        if profile.correlations.contains(where: { $0.contains("sleep") }) {
            tips.append(contentsOf: all.filter { $0.category == .sleep })
        }

        if tips.isEmpty {
            tips = Array(all.filter { $0.category == .general || $0.category == .activity }.prefix(3))
        }

        var seen = Set<String>()
        return tips.filter { seen.insert($0.id).inserted }.prefix(4).map { $0 }
    }
}
