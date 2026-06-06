import SwiftUI

struct HealthSignalDetailSheet: View {
    let signal: HealthSignal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDependencies) private var dependencies

    @State private var aiExplanation: String?
    @State private var isLoadingExplanation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    aiExplanationSection
                    evidenceSection
                    if !signal.suggestedQuestions.isEmpty {
                        questionsSection
                    }
                    disclaimerSection
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Signal Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadExplanation()
            }
        }
    }

    private var aiExplanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What this means")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if isLoadingExplanation {
                ProgressView()
            } else {
                Text(aiExplanation ?? signal.detail)
                    .font(.body)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private func loadExplanation() async {
        isLoadingExplanation = true
        defer { isLoadingExplanation = false }
        aiExplanation = await dependencies.onDeviceHealthAI.explainSignal(signal)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(severityColor)
                    .frame(width: 12, height: 12)
                Text(severityLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(severityColor)
            }

            Text(signal.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(NHSTheme.textPrimary)

            Text(signal.detail)
                .font(.body)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evidence")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(signal.evidence) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: sourceIcon(item.source))
                        .foregroundStyle(NHSTheme.primaryBlue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(NHSTheme.textPrimary)
                        Text(item.value)
                            .font(.subheadline)
                            .foregroundStyle(NHSTheme.textSecondary)
                        if let detail = item.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                        Text(sourceLabel(item.source))
                            .font(.caption2)
                            .foregroundStyle(NHSTheme.textSecondary.opacity(0.8))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Questions for your GP")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(signal.suggestedQuestions, id: \.self) { question in
                Label(question, systemImage: "questionmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var disclaimerSection: some View {
        Text("This signal is generated on your device from your data. It is not a diagnosis. Consider discussing concerns with your GP.")
            .font(.caption)
            .foregroundStyle(NHSTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .nhsCard()
    }

    private var severityColor: Color {
        switch signal.severity {
        case .discussWithGP: .red
        case .watch: .orange
        case .info: NHSTheme.primaryBlue
        }
    }

    private var severityLabel: String {
        switch signal.severity {
        case .discussWithGP: "Discuss with GP"
        case .watch: "Worth watching"
        case .info: "Information"
        }
    }

    private func sourceIcon(_ source: EvidenceItem.Source) -> String {
        switch source {
        case .screening: "checklist"
        case .healthKit: "heart.text.square"
        case .lab: "flask"
        case .lifestyle: "figure.walk"
        }
    }

    private func sourceLabel(_ source: EvidenceItem.Source) -> String {
        switch source {
        case .screening: "Validated screening"
        case .healthKit: "HealthKit"
        case .lab: "Lab result"
        case .lifestyle: "Lifestyle measure"
        }
    }
}

#Preview {
    HealthSignalDetailSheet(
        signal: HealthSignal(
            id: "sleep_anxiety",
            kind: .correlation,
            title: "Poor sleep with anxiety",
            detail: "Short sleep alongside elevated anxiety scores often go together.",
            evidence: [
                EvidenceItem(source: .healthKit, label: "Sleep average", value: "5.0 hours"),
                EvidenceItem(source: .screening, label: "GAD-7", value: "12/21")
            ],
            suggestedQuestions: ["Could my sleep and anxiety be connected?"],
            severity: .watch,
            bodyRegion: .brain,
            createdAt: .now
        )
    )
}
