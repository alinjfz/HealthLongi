import SwiftUI

struct HealthSignalsCard: View {
    let signals: [HealthSignal]
    var onSelect: (HealthSignal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Health Signals", systemImage: "waveform.badge.magnifyingglass")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if signals.isEmpty {
                Text("Complete questionnaires and sync HealthKit data to discover cross-domain patterns on your device.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(signals) { signal in
                    Button {
                        onSelect(signal)
                    } label: {
                        signalRow(signal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private func signalRow(_ signal: HealthSignal) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(severityColor(signal.severity))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NHSTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(signal.detail)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private func severityColor(_ severity: HealthSignal.Severity) -> Color {
        switch severity {
        case .discussWithGP: .red
        case .watch: .orange
        case .info: NHSTheme.primaryBlue
        }
    }
}

#Preview {
    HealthSignalsCard(
        signals: [
            HealthSignal(
                id: "sleep_anxiety",
                kind: .correlation,
                title: "Poor sleep with anxiety",
                detail: "Short sleep alongside elevated anxiety scores often go together.",
                evidence: [
                    EvidenceItem(source: .healthKit, label: "Sleep", value: "5h"),
                    EvidenceItem(source: .screening, label: "GAD-7", value: "12/21")
                ],
                suggestedQuestions: ["Could my sleep and anxiety be connected?"],
                severity: .watch,
                bodyRegion: .brain,
                createdAt: .now
            )
        ],
        onSelect: { _ in }
    )
    .padding()
}
