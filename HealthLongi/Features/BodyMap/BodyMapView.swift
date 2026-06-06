import SwiftUI

struct BodyMapView: View {
    let profile: AbstractedRiskProfile
    let snapshot: WeeklyHealthSnapshot
    var signals: [HealthSignal] = []
    var onSelectQuestionnaire: (QuestionnaireKind) -> Void

    @State private var selectedRegion: BodyRegion?

    private var regionColors: [BodyRegion: Color] {
        Dictionary(uniqueKeysWithValues: BodyRegion.allCases.map { region in
            (region, BodyRegionMapping.color(for: region, profile: profile, snapshot: snapshot, signals: signals))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Body Health Map", systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Tap a highlighted region to see related health signals or open a screening.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)

            HumanBodySceneView(regionColors: regionColors) { region in
                selectedRegion = region
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BodyRegion.allCases) { region in
                        Button {
                            selectedRegion = region
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(regionColors[region] ?? .gray)
                                    .frame(width: 10, height: 10)
                                Text(region.displayName)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(NHSTheme.lightBlue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
        .sheet(item: $selectedRegion) { region in
            BodyRegionSignalsSheet(
                region: region,
                signals: BodyMapSignalMapper.signals(for: region, from: signals),
                onOpenQuestionnaire: { onSelectQuestionnaire(region.questionnaire) }
            )
        }
    }
}

private struct BodyRegionSignalsSheet: View {
    let region: BodyRegion
    let signals: [HealthSignal]
    let onOpenQuestionnaire: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if signals.isEmpty {
                    Section {
                        Text("No active signals for this region.")
                            .foregroundStyle(NHSTheme.textSecondary)
                        Button("Open \(region.questionnaire.title)") {
                            dismiss()
                            onOpenQuestionnaire()
                        }
                    }
                } else {
                    Section("Signals") {
                        ForEach(signals) { signal in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(signal.title)
                                    .font(.headline)
                                Text(signal.detail)
                                    .font(.caption)
                                    .foregroundStyle(NHSTheme.textSecondary)
                                ForEach(signal.evidence) { item in
                                    Text("\(item.label): \(item.value)")
                                        .font(.caption2)
                                        .foregroundStyle(NHSTheme.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(region.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
