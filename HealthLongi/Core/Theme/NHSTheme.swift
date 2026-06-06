import SwiftUI

enum NHSTheme {
    // MARK: - Adaptive Colors

    static let primaryBlue = Color(
        light: Color(red: 0.0, green: 0.28, blue: 0.67),
        dark: Color(red: 0.35, green: 0.60, blue: 0.95)
    )

    static let lightBlue = Color(
        light: Color(red: 0.85, green: 0.93, blue: 0.98),
        dark: Color(red: 0.15, green: 0.22, blue: 0.35)
    )

    static let darkBlue = Color(
        light: Color(red: 0.0, green: 0.19, blue: 0.45),
        dark: Color(red: 0.55, green: 0.75, blue: 1.0)
    )

    static let background = Color(
        light: Color(red: 0.98, green: 0.99, blue: 1.0),
        dark: Color(red: 0.0, green: 0.0, blue: 0.0)
    )

    static let cardBackground = Color(
        light: .white,
        dark: Color(red: 0.11, green: 0.11, blue: 0.12)
    )

    static let textPrimary = Color(
        light: Color(red: 0.12, green: 0.16, blue: 0.22),
        dark: Color(red: 0.95, green: 0.95, blue: 0.97)
    )

    static let textSecondary = Color(
        light: Color(red: 0.35, green: 0.42, blue: 0.50),
        dark: Color(red: 0.65, green: 0.65, blue: 0.70)
    )

    // MARK: - Risk Colors (semantic — already adapt via SwiftUI)

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

// MARK: - Adaptive Color Initializer

private extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Button Style

struct NHSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

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

// MARK: - Card Style

struct NHSCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(NHSTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: colorScheme == .dark
                    ? .white.opacity(0.04)
                    : .black.opacity(0.06),
                radius: 8, y: 2
            )
    }
}

extension View {
    func nhsCard() -> some View {
        modifier(NHSCardStyle())
    }
}
