import SwiftUI

struct TrendsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Health Trends", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Weekly patterns from Apple Health on your device.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)

            TrendsContentView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }
}

#Preview {
    TrendsCard()
        .padding()
        .environment(\.appDependencies, .preview())
}
