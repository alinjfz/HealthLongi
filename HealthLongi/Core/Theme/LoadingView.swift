import SwiftUI

struct LoadingView: View {
    var message: String = "Analysing your health data…"

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(NHSTheme.primaryBlue)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
                .multilineTextAlignment(.center)

            SkeletonCard()
            SkeletonCard()
            SkeletonCard()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NHSTheme.background)
    }
}

private struct SkeletonCard: View {
    @State private var animating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(NHSTheme.lightBlue.opacity(animating ? 0.5 : 0.9))
            .frame(height: 80)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    animating = true
                }
            }
    }
}

#Preview {
    LoadingView()
}
