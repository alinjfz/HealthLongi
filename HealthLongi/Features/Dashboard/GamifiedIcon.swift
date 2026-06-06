import SwiftUI

struct GamifiedIcon: View {
    let tip: HealthTip
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : NHSTheme.primaryBlue)
                    .frame(width: 36, height: 36)
                    .background((isCompleted ? Color.green : NHSTheme.primaryBlue).opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(tip.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text(tip.description)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? .green : NHSTheme.textSecondary)
                    .symbolEffect(.bounce, value: isCompleted)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isCompleted)
    }
}
