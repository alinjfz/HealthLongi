import SwiftUI

struct QuestionnaireCompletionView: View {
    let title: String
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Thank you")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Your \(title) check-in has been saved. We'll use this privately to support your health insights — you won't see a score here.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Done") { onDone() }
                .buttonStyle(NHSPrimaryButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NHSTheme.background)
    }
}
