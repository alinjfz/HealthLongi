import SwiftUI
import Charts

struct DNAVariantChartView: View {
    let variants: [MockDNAVariant]

    private struct ChartRow: Identifiable {
        let id: String
        let gene: String
        let category: GeneticsCategory
        let riskScore: Int
        let riskLevel: RiskLevel
    }

    private var chartData: [ChartRow] {
        variants.map { variant in
            ChartRow(
                id: variant.id,
                gene: variant.gene,
                category: variant.category,
                riskScore: riskScore(for: variant.riskLevel),
                riskLevel: variant.riskLevel
            )
        }
        .sorted { $0.riskScore > $1.riskScore }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DNA Variant Preview")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Mock demo data — not from a real genetic test.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)

            if chartData.isEmpty {
                Text("Upload a DNA report to see variant highlights.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(chartData) { row in
                    BarMark(
                        x: .value("Risk", row.riskScore),
                        y: .value("Gene", row.gene)
                    )
                    .foregroundStyle(NHSTheme.riskColor(for: row.riskLevel))
                    .annotation(position: .trailing) {
                        Text(row.riskLevel.displayName)
                            .font(.caption2)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
                .chartXScale(domain: 0...3)
                .chartXAxis {
                    AxisMarks(values: [1, 2, 3]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text(riskLabel(for: intVal))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: min(320, CGFloat(chartData.count) * 36 + 40))
            }
        }
        .nhsCard()
    }

    private func riskScore(for level: RiskLevel) -> Int {
        switch level {
        case .low: 1
        case .moderate: 2
        case .high: 3
        }
    }

    private func riskLabel(for score: Int) -> String {
        switch score {
        case 1: "Low"
        case 2: "Mod"
        default: "High"
        }
    }
}

struct GeneConditionMapView: View {
    let variants: [MockDNAVariant]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genes & Related Conditions")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if variants.isEmpty {
                Text("No mock variants loaded yet.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                ForEach(variants) { variant in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(variant.displayLabel)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(variant.riskLevel.displayName)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(NHSTheme.riskColor(for: variant.riskLevel).opacity(0.15))
                                .foregroundStyle(NHSTheme.riskColor(for: variant.riskLevel))
                                .clipShape(Capsule())
                        }

                        Text(variant.category.title)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)

                        let linked = MockDNAReport.conditions(for: variant)
                        if linked.isEmpty {
                            Text(variant.relatedConditions.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textPrimary)
                        } else {
                            FlowLayout(spacing: 6) {
                                ForEach(linked) { condition in
                                    Text(condition.condition)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(NHSTheme.lightBlue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .nhsCard()
                }
            }
        }
    }
}

/// Simple horizontal flow layout for gene/condition chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
