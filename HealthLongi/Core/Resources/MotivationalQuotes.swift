import Foundation

struct MotivationalQuote: Identifiable, Sendable {
    let id = UUID()
    let quote: String
    let category: HealthCategory
}

enum HealthCategory: Sendable {
    case general, mental, physical, sleep, activity

    var icon: String {
        switch self {
        case .general: "sparkles"
        case .mental: "brain.head.profile"
        case .physical: "heart.fill"
        case .sleep: "moon.fill"
        case .activity: "figure.walk"
        }
    }
}

enum MotivationalQuotes {
    static let all: [MotivationalQuote] = [
        MotivationalQuote(
            quote: "Every step you take towards better health is a victory worth celebrating.",
            category: .general
        ),
        MotivationalQuote(
            quote: "Your mental health is just as important as your physical health.",
            category: .mental
        ),
        MotivationalQuote(
            quote: "Small consistent actions lead to big health improvements over time.",
            category: .activity
        ),
        MotivationalQuote(
            quote: "Quality sleep is the foundation of a healthy lifestyle.",
            category: .sleep
        ),
        MotivationalQuote(
            quote: "Taking care of your heart is an act of self-love that pays dividends for life.",
            category: .physical
        )
    ]

    static func random(for category: HealthCategory? = nil) -> MotivationalQuote {
        if let category {
            let filtered = all.filter { $0.category == category }
            if let pick = filtered.randomElement() { return pick }
        }
        return all.randomElement() ?? all[0]
    }
}
