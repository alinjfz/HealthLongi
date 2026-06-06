import SwiftUI

struct GenderIdentityView: View {
    @Binding var genderIdentity: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender identity")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NHSTheme.textPrimary)

            TextField("How do you identify?", text: $genderIdentity)
                .textFieldStyle(.roundedBorder)

            Text("Optional. This is separate from sex at birth and used only on your device.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
        }
    }
}
