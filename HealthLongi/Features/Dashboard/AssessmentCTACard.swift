import SwiftUI

struct AssessmentCTACard: View {
    let profile: UserProfile?
    let readiness: (completed: Int, total: Int, items: [ReadinessItem])
    let hasNewData: Bool
    let isLoading: Bool
    let onRun: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow

            readinessProgress

            readinessChecklist

            actionButton
        }
        .nhsCard()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(NHSTheme.primaryBlue)
                .symbolEffect(.bounce, value: hasNewData)

            VStack(alignment: .leading, spacing: 2) {
                Text(hasNewData ? "New Data Available" : "Health Assessment")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.textPrimary)
                Text(hasNewData ? "Your health data has changed — run an updated assessment" : "Complete all sources for the most accurate results")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
    }

    // MARK: - Progress Bar

    private var readinessProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Readiness")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(NHSTheme.textSecondary)
                Spacer()
                Text("\(readiness.completed)/\(readiness.total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NHSTheme.primaryBlue)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NHSTheme.lightBlue)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(
                            width: readiness.total > 0
                                ? geo.size.width * CGFloat(readiness.completed) / CGFloat(readiness.total)
                                : 0,
                            height: 6
                        )
                        .animation(.spring(duration: 0.5), value: readiness.completed)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressColor: Color {
        switch readiness.completed {
        case readiness.total: return .green
        case 1...: return NHSTheme.primaryBlue
        default: return NHSTheme.textSecondary
        }
    }

    // MARK: - Checklist

    private var readinessChecklist: some View {
        VStack(spacing: 6) {
            ForEach(readiness.items, id: \.title) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline)
                        .foregroundStyle(item.isComplete ? .green : NHSTheme.textSecondary)
                        .symbolEffect(.bounce, value: item.isComplete)

                    Text(item.title)
                        .font(.subheadline)
                        .foregroundStyle(item.isComplete ? NHSTheme.textPrimary : NHSTheme.textSecondary)

                    Spacer()

                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            onRun()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: readiness.completed == readiness.total ? "bolt.fill" : "arrow.right.circle.fill")
                        .font(.title3)
                }

                Text(buttonLabel)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var buttonLabel: String {
        if isLoading { return "Analysing…" }
        if hasNewData { return "Update Assessment" }
        if readiness.completed == readiness.total { return "Run Assessment" }
        return "Run Assessment"
    }

    private var buttonBackground: Color {
        if readiness.completed == readiness.total || hasNewData {
            return NHSTheme.primaryBlue
        }
        return NHSTheme.primaryBlue.opacity(0.6)
    }
}

#Preview {
    VStack {
        AssessmentCTACard(
            profile: nil,
            readiness: (3, 4, [
                ReadinessItem(title: "PHQ-9 Questionnaire", icon: "brain.head.profile", isComplete: true),
                ReadinessItem(title: "GAD-7 Questionnaire", icon: "waveform.path.ecg", isComplete: true),
                ReadinessItem(title: "HealthKit Data", icon: "heart.text.square.fill", isComplete: false),
                ReadinessItem(title: "Demographics", icon: "person.fill", isComplete: true)
            ]),
            hasNewData: false,
            isLoading: false,
            onRun: {}
        )

        AssessmentCTACard(
            profile: nil,
            readiness: (4, 4, [
                ReadinessItem(title: "PHQ-9 Questionnaire", icon: "brain.head.profile", isComplete: true),
                ReadinessItem(title: "GAD-7 Questionnaire", icon: "waveform.path.ecg", isComplete: true),
                ReadinessItem(title: "HealthKit Data", icon: "heart.text.square.fill", isComplete: true),
                ReadinessItem(title: "Demographics", icon: "person.fill", isComplete: true)
            ]),
            hasNewData: true,
            isLoading: false,
            onRun: {}
        )
    }
    .padding()
}
