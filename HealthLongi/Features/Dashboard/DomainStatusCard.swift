import SwiftUI

struct DomainStatusCard: View {
    let title: String
    let subtitle: String
    let status: String
    let color: Color
    let icon: String

    var body: some View {
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

            Text(status)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
        }
        .nhsCard()
    }
}

#Preview {
    DomainStatusCard(
        title: "Cardiovascular",
        subtitle: "Heart & circulation",
        status: "Moderate",
        color: .orange,
        icon: "heart.fill"
    )
    .padding()
}
