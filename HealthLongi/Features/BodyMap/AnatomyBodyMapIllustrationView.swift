import SwiftUI

struct BodyMapHeroBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.10),
                    Color(red: 0.05, green: 0.10, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    NHSTheme.primaryBlue.opacity(0.35),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 220
            )
        }
    }
}

struct AnatomyBodyMapIllustrationView: View {
    let regionColors: [BodyRegion: Color]
    let organStyles: [AnatomyOrganID: (color: Color, opacity: Double)]
    var onRegionTapped: (BodyRegion) -> Void

    private static let canvasAspect: CGFloat = 720 / 1280

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                BodyMapHeroBackground()

                Image("body_base")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)

                ForEach(AnatomyOrganID.renderOrder) { organ in
                    let style = organStyle(for: organ)
                    AnatomyOrganLayerView(
                        organ: organ,
                        tintColor: style.color,
                        tintOpacity: style.opacity
                    )
                    .frame(width: size.width, height: size.height)
                    .clipped()
                }

                hotspotMarkers(in: size)
                touchTargets(in: size)
            }
            .accessibilityElement(children: .contain)
        }
        .aspectRatio(Self.canvasAspect, contentMode: .fit)
    }

    @ViewBuilder
    private func touchTargets(in size: CGSize) -> some View {
        ForEach(BodyRegion.allCases) { region in
            let data = markerData(for: region)
            Color.clear
                .frame(width: data.size.width, height: data.size.height)
                .contentShape(Rectangle())
                .onTapGesture { onRegionTapped(region) }
                .position(x: size.width * data.center.x, y: size.height * data.center.y)
                .accessibilityLabel("\(region.displayName) health status")
                .accessibilityHint("Opens the related health screening")
                .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    private func hotspotMarkers(in size: CGSize) -> some View {
        ForEach(BodyRegion.allCases) { region in
            let data = markerData(for: region)
            let color = regionColor(region)

            ZStack {
                Circle()
                    .fill(color.opacity(0.28))
                    .frame(width: 38, height: 38)
                    .shadow(color: color.opacity(0.7), radius: 8)

                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1))

                Image(systemName: "plus")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .allowsHitTesting(false)
            .position(x: size.width * data.center.x, y: size.height * data.center.y)
        }
    }

    private func markerData(for region: BodyRegion) -> (center: CGPoint, size: CGSize) {
        switch region {
        case .brain:
            (CGPoint(x: 0.50, y: 0.11), CGSize(width: 88, height: 72))
        case .heart:
            (CGPoint(x: 0.47, y: 0.30), CGSize(width: 76, height: 68))
        case .lungs:
            (CGPoint(x: 0.50, y: 0.27), CGSize(width: 132, height: 120))
        case .abdomen:
            (CGPoint(x: 0.51, y: 0.46), CGSize(width: 110, height: 110))
        case .leftShoulder:
            (CGPoint(x: 0.28, y: 0.27), CGSize(width: 76, height: 72))
        case .rightHip:
            (CGPoint(x: 0.58, y: 0.60), CGSize(width: 82, height: 78))
        case .leftKnee:
            (CGPoint(x: 0.42, y: 0.82), CGSize(width: 74, height: 70))
        }
    }

    private func organStyle(for organ: AnatomyOrganID) -> (color: Color, opacity: Double) {
        organStyles[organ] ?? (organ.restingTint, 0.38)
    }

    private func regionColor(_ region: BodyRegion) -> Color {
        regionColors[region] ?? .gray
    }
}
