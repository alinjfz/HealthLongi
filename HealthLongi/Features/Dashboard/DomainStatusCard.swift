import SwiftUI

struct DomainStatusCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
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

                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }
            .nhsCard()
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

#Preview {
    DomainStatusCard(
        title: "Cardiovascular",
        subtitle: "Heart & circulation",
        color: .orange,
        icon: "heart.fill",
        action: {}
    )
    .padding()
}
