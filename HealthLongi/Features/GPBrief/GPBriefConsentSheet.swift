import SwiftUI

struct GPBriefConsentSheet: View {
    let onAccept: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Before you share")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(NHSTheme.textPrimary)

                    Text("The GP Visit Brief summarises your on-device health data. It is not a medical diagnosis and should be discussed with a qualified professional.")
                        .font(.body)
                        .foregroundStyle(NHSTheme.textSecondary)

                    Text("By continuing, you confirm you understand this brief is for discussion purposes only.")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)

                    Button("I understand — show brief") {
                        onAccept()
                        dismiss()
                    }
                    .buttonStyle(NHSPrimaryButtonStyle())
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
