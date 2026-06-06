import SwiftUI

struct BodyMapView: View {
    let profile: AbstractedRiskProfile
    let snapshot: WeeklyHealthSnapshot
    var onSelectQuestionnaire: (QuestionnaireKind) -> Void

    private var regionColors: [BodyRegion: Color] {
        Dictionary(uniqueKeysWithValues: BodyRegion.allCases.map { region in
            (region, BodyRegionMapping.color(for: region, profile: profile, snapshot: snapshot))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Body Health Map", systemImage: "figure.stand")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Tap a highlighted region to open its related screening. Pinch and drag to explore the 3D view.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)

            HumanBodySceneView(regionColors: regionColors) { region in
                onSelectQuestionnaire(region.questionnaire)
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BodyRegion.allCases) { region in
                        Button {
                            onSelectQuestionnaire(region.questionnaire)
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
    }
}
