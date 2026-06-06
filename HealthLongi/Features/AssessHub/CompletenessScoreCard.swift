import SwiftUI

struct CompletenessScoreCard: View {
    let score: Int
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(NHSTheme.lightBlue, lineWidth: 8)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(NHSTheme.primaryBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                    Text("\(score)%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(NHSTheme.primaryBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Screening completeness")
                        .font(.headline)
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text("Tap to see what's missing")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NHSTheme.textSecondary)
            }
            .nhsCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CompletenessScoreCard(score: 55, onTap: {})
        .padding()
}
