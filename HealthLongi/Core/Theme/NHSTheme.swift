import SwiftUI

enum NHSTheme {
    static let primaryBlue = Color(red: 0.0, green: 0.28, blue: 0.67)
    static let lightBlue = Color(red: 0.85, green: 0.93, blue: 0.98)
    static let darkBlue = Color(red: 0.0, green: 0.19, blue: 0.45)
    static let background = Color(red: 0.98, green: 0.99, blue: 1.0)
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.22)
    static let textSecondary = Color(red: 0.35, green: 0.42, blue: 0.50)

    static func riskColor(for level: RiskLevel) -> Color {
        switch level {
        case .low: .green
        case .moderate: .orange
        case .high: .red
        }
    }

    static func mentalColor(for flag: MentalFlag) -> Color {
        switch flag {
        case .none, .mild: .green
        case .moderateDepression, .moderateAnxiety: .orange
        case .severeDepression, .highAnxiety: .red
        }
    }
}

struct NHSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(NHSTheme.primaryBlue.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct NHSCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(NHSTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

extension View {
    func nhsCard() -> some View {
        modifier(NHSCardStyle())
    }
}
