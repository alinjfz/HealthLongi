import SwiftUI

struct AnatomyBodyMapIllustrationView: View {
    let regionColors: [BodyRegion: Color]
    let selectedRegion: BodyRegion?
    var onRegionTapped: (BodyRegion) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                background

                Group {
                    AnatomySilhouette()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.30, blue: 0.45).opacity(0.86),
                                    Color(red: 0.07, green: 0.12, blue: 0.20).opacity(0.96)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(AnatomySilhouette().stroke(Color(red: 0.58, green: 0.78, blue: 1.0).opacity(0.55), lineWidth: 1.5))
                        .overlay(AnatomySilhouette().stroke(.white.opacity(0.22), lineWidth: 0.6).blur(radius: 2))
                        .shadow(color: Color(red: 0.26, green: 0.55, blue: 1.0).opacity(0.5), radius: 18)
                        .shadow(color: .black.opacity(0.55), radius: 22, y: 14)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)

                    VascularLines()
                        .stroke(Color(red: 0.93, green: 0.16, blue: 0.22).opacity(0.50), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)

                    VascularLines()
                        .stroke(Color(red: 0.20, green: 0.62, blue: 1.0).opacity(0.32), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                        .offset(x: 7)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)

                    SkeletonLines()
                        .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)

                    organs
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                }
                .scaleEffect(1.04)

                hotspotMarkers(in: size)

                touchTargets(in: size)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
        }
    }

    private var background: some View {
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

    private var organs: some View {
        ZStack {
            BrainShape()
                .fill(regionColor(.brain).opacity(0.92))
                .overlay(BrainShape().stroke(.white.opacity(0.72), lineWidth: 1.2))
                .shadow(color: regionColor(.brain).opacity(0.85), radius: 13)
                .frame(width: 58, height: 42)
                .position(x: 150, y: 56)

            LungsShape()
                .fill(regionColor(.lungs).opacity(0.88))
                .overlay(LungsShape().stroke(.white.opacity(0.7), lineWidth: 1.2))
                .shadow(color: regionColor(.lungs).opacity(0.8), radius: 14)
                .frame(width: 116, height: 118)
                .position(x: 150, y: 158)

            HeartShape()
                .fill(regionColor(.heart).opacity(0.95))
                .overlay(HeartShape().stroke(.white.opacity(0.76), lineWidth: 1.2))
                .shadow(color: regionColor(.heart).opacity(0.9), radius: 13)
                .frame(width: 43, height: 43)
                .position(x: 141, y: 166)

            LiverShape()
                .fill(regionColor(.abdomen).opacity(0.80))
                .overlay(LiverShape().stroke(.white.opacity(0.55), lineWidth: 1))
                .shadow(color: regionColor(.abdomen).opacity(0.65), radius: 10)
                .frame(width: 96, height: 56)
                .position(x: 138, y: 221)

            StomachShape()
                .fill(regionColor(.abdomen).opacity(0.92))
                .overlay(StomachShape().stroke(.white.opacity(0.72), lineWidth: 1.2))
                .shadow(color: regionColor(.abdomen).opacity(0.85), radius: 13)
                .frame(width: 58, height: 70)
                .position(x: 174, y: 238)

            IntestineShape()
                .stroke(regionColor(.abdomen).opacity(0.95), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                .overlay(
                    IntestineShape()
                        .stroke(.white.opacity(0.38), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                )
                .shadow(color: regionColor(.abdomen).opacity(0.85), radius: 12)
                .frame(width: 98, height: 76)
                .position(x: 151, y: 283)

            TracheaShape()
                .stroke(Color(red: 0.16, green: 0.78, blue: 0.92).opacity(0.72), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 36, height: 84)
                .position(x: 150, y: 118)

            joint(.leftShoulder, diameter: 37)
                .position(x: 82, y: 132)

            joint(.rightHip, diameter: 42)
                .position(x: 181, y: 310)

            joint(.leftKnee, diameter: 34)
                .position(x: 118, y: 452)
        }
        .frame(width: 300, height: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func joint(_ region: BodyRegion, diameter: CGFloat) -> some View {
        Circle()
            .fill(regionColor(region).opacity(0.82))
            .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1.1))
            .shadow(color: regionColor(region).opacity(0.85), radius: 11)
            .frame(width: diameter, height: diameter)
    }

    @ViewBuilder
    private func touchTargets(in size: CGSize) -> some View {
        ForEach(BodyRegion.allCases) { region in
            let data = markerData(for: region)
            regionButton(region, center: data.center, size: data.size, in: size)
        }
    }

    @ViewBuilder
    private func hotspotMarkers(in size: CGSize) -> some View {
        ForEach(BodyRegion.allCases) { region in
            let data = markerData(for: region)
            Button {
                onRegionTapped(region)
            } label: {
                ZStack {
                    Circle()
                        .fill(regionColor(region).opacity(region == selectedRegion ? 0.35 : 0.22))
                        .frame(width: region == selectedRegion ? 42 : 34, height: region == selectedRegion ? 42 : 34)
                        .shadow(color: regionColor(region).opacity(0.85), radius: region == selectedRegion ? 14 : 9)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 1))

                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .position(x: size.width * data.center.x, y: size.height * data.center.y)
        }
    }

    private func markerData(for region: BodyRegion) -> (center: CGPoint, size: CGSize) {
        switch region {
        case .brain:
            (CGPoint(x: 0.50, y: 0.12), CGSize(width: 86, height: 70))
        case .heart:
            (CGPoint(x: 0.48, y: 0.31), CGSize(width: 76, height: 68))
        case .lungs:
            (CGPoint(x: 0.50, y: 0.28), CGSize(width: 132, height: 122))
        case .abdomen:
            (CGPoint(x: 0.52, y: 0.47), CGSize(width: 108, height: 108))
        case .leftShoulder:
            (CGPoint(x: 0.30, y: 0.28), CGSize(width: 76, height: 72))
        case .rightHip:
            (CGPoint(x: 0.59, y: 0.61), CGSize(width: 82, height: 78))
        case .leftKnee:
            (CGPoint(x: 0.43, y: 0.84), CGSize(width: 74, height: 70))
        }
    }

    private func regionButton(_ region: BodyRegion, center: CGPoint, size buttonSize: CGSize, in containerSize: CGSize) -> some View {
        Button {
            onRegionTapped(region)
        } label: {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: buttonSize.width, height: buttonSize.height)
        .position(x: containerSize.width * center.x, y: containerSize.height * center.y)
        .accessibilityLabel("\(region.displayName) health status")
        .accessibilityHint("Opens the related health screening")
    }

    private func regionColor(_ region: BodyRegion) -> Color {
        regionColors[region] ?? .gray
    }
}

private struct AnatomySilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 300, rect.height / 520)
        let x = rect.midX - 150 * scale
        let y = rect.midY - 260 * scale

        func p(_ px: CGFloat, _ py: CGFloat) -> CGPoint {
            CGPoint(x: x + px * scale, y: y + py * scale)
        }

        var path = Path()
        path.move(to: p(150, 18))
        path.addCurve(to: p(111, 58), control1: p(126, 18), control2: p(111, 35))
        path.addCurve(to: p(132, 98), control1: p(111, 76), control2: p(119, 90))
        path.addLine(to: p(132, 113))
        path.addCurve(to: p(81, 121), control1: p(116, 113), control2: p(97, 115))
        path.addCurve(to: p(48, 171), control1: p(62, 128), control2: p(51, 145))
        path.addLine(to: p(30, 292))
        path.addCurve(to: p(53, 300), control1: p(28, 307), control2: p(49, 312))
        path.addLine(to: p(78, 198))
        path.addCurve(to: p(96, 155), control1: p(82, 179), control2: p(86, 164))
        path.addCurve(to: p(103, 236), control1: p(89, 185), control2: p(91, 212))
        path.addCurve(to: p(119, 315), control1: p(109, 264), control2: p(113, 290))
        path.addLine(to: p(94, 494))
        path.addCurve(to: p(128, 504), control1: p(91, 516), control2: p(125, 520))
        path.addLine(to: p(146, 334))
        path.addCurve(to: p(154, 334), control1: p(148, 329), control2: p(152, 329))
        path.addLine(to: p(172, 504))
        path.addCurve(to: p(206, 494), control1: p(175, 520), control2: p(209, 516))
        path.addLine(to: p(181, 315))
        path.addCurve(to: p(197, 236), control1: p(187, 290), control2: p(191, 264))
        path.addCurve(to: p(204, 155), control1: p(209, 212), control2: p(211, 185))
        path.addCurve(to: p(222, 198), control1: p(214, 164), control2: p(218, 179))
        path.addLine(to: p(247, 300))
        path.addCurve(to: p(270, 292), control1: p(251, 312), control2: p(272, 307))
        path.addLine(to: p(252, 171))
        path.addCurve(to: p(219, 121), control1: p(249, 145), control2: p(238, 128))
        path.addCurve(to: p(168, 113), control1: p(203, 115), control2: p(184, 113))
        path.addLine(to: p(168, 98))
        path.addCurve(to: p(189, 58), control1: p(181, 90), control2: p(189, 76))
        path.addCurve(to: p(150, 18), control1: p(189, 35), control2: p(174, 18))
        path.closeSubpath()

        return path
    }
}

private struct SkeletonLines: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 300, rect.height / 520)
        let x = rect.midX - 150 * scale
        let y = rect.midY - 260 * scale

        func p(_ px: CGFloat, _ py: CGFloat) -> CGPoint {
            CGPoint(x: x + px * scale, y: y + py * scale)
        }

        var path = Path()
        path.move(to: p(150, 96))
        path.addLine(to: p(150, 322))
        path.move(to: p(100, 128))
        path.addCurve(to: p(200, 128), control1: p(128, 112), control2: p(172, 112))
        path.move(to: p(121, 316))
        path.addCurve(to: p(179, 316), control1: p(139, 332), control2: p(161, 332))
        path.move(to: p(78, 198))
        path.addLine(to: p(54, 292))
        path.move(to: p(222, 198))
        path.addLine(to: p(246, 292))
        path.move(to: p(122, 322))
        path.addLine(to: p(110, 492))
        path.move(to: p(178, 322))
        path.addLine(to: p(190, 492))
        return path
    }
}

private struct VascularLines: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 300, rect.height / 520)
        let x = rect.midX - 150 * scale
        let y = rect.midY - 260 * scale

        func p(_ px: CGFloat, _ py: CGFloat) -> CGPoint {
            CGPoint(x: x + px * scale, y: y + py * scale)
        }

        var path = Path()

        // Neck into torso
        path.move(to: p(150, 84))
        path.addCurve(to: p(148, 188), control1: p(144, 118), control2: p(144, 152))
        path.addCurve(to: p(140, 268), control1: p(151, 218), control2: p(147, 244))

        // Chest branches
        path.move(to: p(148, 132))
        path.addCurve(to: p(98, 132), control1: p(133, 120), control2: p(115, 119))
        path.move(to: p(152, 132))
        path.addCurve(to: p(202, 132), control1: p(167, 120), control2: p(185, 119))

        // Arms
        path.move(to: p(98, 132))
        path.addCurve(to: p(70, 202), control1: p(82, 155), control2: p(74, 178))
        path.addCurve(to: p(48, 288), control1: p(66, 234), control2: p(54, 260))
        path.move(to: p(202, 132))
        path.addCurve(to: p(230, 202), control1: p(218, 155), control2: p(226, 178))
        path.addCurve(to: p(252, 288), control1: p(234, 234), control2: p(246, 260))

        // Abdomen and pelvis
        path.move(to: p(140, 268))
        path.addCurve(to: p(121, 323), control1: p(130, 288), control2: p(122, 304))
        path.move(to: p(140, 268))
        path.addCurve(to: p(179, 323), control1: p(160, 286), control2: p(176, 304))

        // Legs
        path.move(to: p(121, 323))
        path.addCurve(to: p(111, 420), control1: p(115, 358), control2: p(112, 388))
        path.addCurve(to: p(104, 504), control1: p(108, 455), control2: p(104, 482))
        path.move(to: p(179, 323))
        path.addCurve(to: p(189, 420), control1: p(185, 358), control2: p(188, 388))
        path.addCurve(to: p(196, 504), control1: p(192, 455), control2: p(196, 482))

        return path
    }
}

private struct BrainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect.insetBy(dx: 4, dy: 7), cornerSize: CGSize(width: rect.height * 0.45, height: rect.height * 0.45))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.08, width: rect.width * 0.28, height: rect.height * 0.44))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.54, y: rect.minY + rect.height * 0.08, width: rect.width * 0.28, height: rect.height * 0.44))
        return path
    }
}

private struct LungsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let topY = rect.minY + rect.height * 0.04
        let bottomY = rect.maxY - rect.height * 0.06

        path.move(to: CGPoint(x: midX - 8, y: topY))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: bottomY),
            control1: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.14),
            control2: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.minY + rect.height * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: midX - 8, y: rect.minY + rect.height * 0.28),
            control1: CGPoint(x: rect.minX + rect.width * 0.5, y: rect.maxY),
            control2: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.38)
        )
        path.closeSubpath()

        path.move(to: CGPoint(x: midX + 8, y: topY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: bottomY),
            control1: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.14),
            control2: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: midX + 8, y: rect.minY + rect.height * 0.28),
            control1: CGPoint(x: rect.maxX - rect.width * 0.5, y: rect.maxY),
            control2: CGPoint(x: rect.maxX - rect.width * 0.42, y: rect.minY + rect.height * 0.38)
        )
        path.closeSubpath()

        return path
    }
}

private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.32),
            control1: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY * 0.88),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.28),
            control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.04),
            control2: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.32),
            control1: CGPoint(x: rect.maxX - rect.width * 0.35, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.04)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.55),
            control2: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY * 0.88)
        )
        return path
    }
}

private struct StomachShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.54),
            control1: CGPoint(x: rect.maxX + rect.width * 0.12, y: rect.minY + rect.height * 0.04),
            control2: CGPoint(x: rect.maxX + rect.width * 0.08, y: rect.minY + rect.height * 0.46)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY - rect.height * 0.08),
            control1: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.maxY),
            control2: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY),
            control1: CGPoint(x: rect.minX - rect.width * 0.06, y: rect.minY + rect.height * 0.68),
            control2: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.08)
        )
        return path
    }
}

private struct LiverShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.45))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY - rect.height * 0.02),
            control2: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.maxY - rect.height * 0.18),
            control1: CGPoint(x: rect.maxX + rect.width * 0.08, y: rect.minY + rect.height * 0.38),
            control2: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.maxY - rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.45),
            control1: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.maxY),
            control2: CGPoint(x: rect.minX - rect.width * 0.04, y: rect.maxY - rect.height * 0.02)
        )
        return path
    }
}

private struct IntestineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows: [CGFloat] = [0.16, 0.36, 0.56, 0.76]

        for (index, row) in rows.enumerated() {
            let y = rect.minY + rect.height * row
            if index.isMultiple(of: 2) {
                path.move(to: CGPoint(x: rect.minX + rect.width * 0.14, y: y))
                path.addCurve(
                    to: CGPoint(x: rect.maxX - rect.width * 0.14, y: y),
                    control1: CGPoint(x: rect.minX + rect.width * 0.34, y: y - rect.height * 0.16),
                    control2: CGPoint(x: rect.maxX - rect.width * 0.34, y: y + rect.height * 0.16)
                )
            } else {
                path.move(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: y))
                path.addCurve(
                    to: CGPoint(x: rect.minX + rect.width * 0.14, y: y),
                    control1: CGPoint(x: rect.maxX - rect.width * 0.34, y: y - rect.height * 0.16),
                    control2: CGPoint(x: rect.minX + rect.width * 0.34, y: y + rect.height * 0.16)
                )
            }
        }

        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.06))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.06),
            control1: CGPoint(x: rect.midX - rect.width * 0.24, y: rect.minY + rect.height * 0.32),
            control2: CGPoint(x: rect.midX + rect.width * 0.24, y: rect.minY + rect.height * 0.68)
        )

        return path
    }
}

private struct TracheaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.62))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY))
        return path
    }
}
