import SwiftUI

struct DNAHelixVisualizationView: View {
    let variants: [MockDNAVariant]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let midX = size.width / 2
                let amplitude = size.width * 0.18
                let steps = 28
                let stepHeight = size.height / CGFloat(steps)

                for index in 0..<steps {
                    let y = CGFloat(index) * stepHeight + stepHeight / 2
                    let angle = phase * 1.4 + Double(index) * 0.45
                    let leftX = midX + CGFloat(sin(angle)) * amplitude
                    let rightX = midX + CGFloat(sin(angle + .pi)) * amplitude

                    var leftPath = Path()
                    leftPath.addEllipse(in: CGRect(x: leftX - 4, y: y - 4, width: 8, height: 8))

                    var rightPath = Path()
                    rightPath.addEllipse(in: CGRect(x: rightX - 4, y: y - 4, width: 8, height: 8))

                    let rungColor = rungColor(for: index)
                    var rung = Path()
                    rung.move(to: CGPoint(x: leftX, y: y))
                    rung.addLine(to: CGPoint(x: rightX, y: y))

                    context.stroke(
                        rung,
                        with: .color(rungColor.opacity(0.8)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    context.fill(leftPath, with: .color(NHSTheme.primaryBlue.opacity(0.9)))
                    context.fill(rightPath, with: .color(Color.green.opacity(0.85)))
                }
            }
        }
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.85), NHSTheme.primaryBlue.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .bottomLeading) {
            Text("Demo DNA helix — mock variant colouring")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
                .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func rungColor(for index: Int) -> Color {
        guard !variants.isEmpty else { return NHSTheme.primaryBlue }
        let variant = variants[index % variants.count]
        return NHSTheme.riskColor(for: variant.riskLevel)
    }
}
