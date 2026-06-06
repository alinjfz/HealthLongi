import SwiftUI

struct AssessmentCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .green : NHSTheme.primaryBlue)
                    .frame(width: 44, height: 44)
                    .background((isCompleted ? Color.green : NHSTheme.primaryBlue).opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }
            .nhsCard()
        }
        .buttonStyle(.plain)
    }
}
