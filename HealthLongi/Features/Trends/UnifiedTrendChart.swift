import SwiftUI
import Charts

struct UnifiedTrendChart: View {
    let series: [TrendSeriesData]
    let usesNormalizedAxis: Bool
    let singleMetric: TrendMetric?

    @State private var selectedPoint: TrendDataPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if series.isEmpty {
                Text("No trend data available for the selected measurements.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart {
                    ForEach(series) { seriesData in
                        if seriesData.metric.displayStyle == .point {
                            ForEach(seriesData.points) { point in
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", yValue(for: point))
                                )
                                .foregroundStyle(pointColor(for: point, series: seriesData))
                                .symbolSize(selectedPoint?.id == point.id ? 90 : 60)
                            }
                        } else {
                            ForEach(seriesData.points) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", yValue(for: point)),
                                    series: .value("Metric", seriesData.metric.title)
                                )
                                .foregroundStyle(seriesData.color)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Date", point.date),
                                    y: .value("Value", yValue(for: point)),
                                    series: .value("Metric", seriesData.metric.title)
                                )
                                .foregroundStyle(seriesData.color.opacity(0.12))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                    }

                    if usesNormalizedAxis {
                        RuleMark(y: .value("Good", HealthStatus.good.rawValue))
                            .foregroundStyle(Color.green.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        RuleMark(y: .value("Moderate", HealthStatus.moderate.rawValue))
                            .foregroundStyle(Color.orange.opacity(0.2))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    if usesNormalizedAxis {
                        AxisMarks(values: HealthStatus.allCases.map(\.rawValue)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let raw = value.as(Double.self),
                                   let status = HealthStatus(rawValue: raw) {
                                    Text(status.label)
                                }
                            }
                        }
                    } else {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                }
                .chartYScale(domain: yDomain)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                selectedPoint = nearestPoint(at: location, proxy: proxy, geometry: geometry)
                            }
                    }
                }
                .frame(height: 220)

                if let selectedPoint {
                    selectedPointDetail(selectedPoint)
                }

                if usesNormalizedAxis {
                    legendView
                } else if let singleMetric {
                    Text(singleMetric.unitLabel)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }
        }
    }

    private var yDomain: ClosedRange<Double> {
        if usesNormalizedAxis {
            return -0.05...1.05
        }
        let values = series.flatMap(\.points).map(\.rawValue)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        if minValue == maxValue {
            let padding = max(abs(minValue) * 0.1, 1)
            return (minValue - padding)...(maxValue + padding)
        }
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }

    private func yValue(for point: TrendDataPoint) -> Double {
        usesNormalizedAxis ? point.status.rawValue : point.rawValue
    }

    private func pointColor(for point: TrendDataPoint, series: TrendSeriesData) -> Color {
        if usesNormalizedAxis {
            point.status.color
        } else {
            series.color
        }
    }

    private var legendView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(series) { seriesData in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(seriesData.color)
                            .frame(width: 8, height: 8)
                        Text(seriesData.metric.title)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
            }
        }
    }

    private func selectedPointDetail(_ point: TrendDataPoint) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(point.status.color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(point.metric.title)
                    .font(.caption.weight(.semibold))
                Text("\(point.formattedValue) · \(point.status.label)")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
            Spacer()
            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .padding(8)
        .background(NHSTheme.lightBlue.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func nearestPoint(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) -> TrendDataPoint? {
        let origin = geometry[proxy.plotAreaFrame].origin
        let xPosition = location.x - origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return nil }

        let allPoints = series.flatMap(\.points)
        return allPoints.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
}

struct TrendMetricSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: TrendsViewModel
    let profileSex: Sex

    @State private var expandedPanels: Set<LabPanel> = [.basic]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Select all") {
                        viewModel.setEnabledMetrics(Set(TrendMetric.allCases))
                    }
                    Button("Clear all") {
                        viewModel.setEnabledMetrics([])
                    }
                }

                Section("Apple Health") {
                    ForEach(TrendMetric.allHealthKitTrendMetrics) { metric in
                        metricToggle(metric)
                    }
                }

                Section("Labs & vitals") {
                    metricToggle(.bloodPressure)

                    ForEach(LabPanel.allCases) { panel in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedPanels.contains(panel) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedPanels.insert(panel)
                                    } else {
                                        expandedPanels.remove(panel)
                                    }
                                }
                            )
                        ) {
                            ForEach(labMetrics(for: panel)) { metric in
                                metricToggle(metric)
                            }
                        } label: {
                            Text(panel.title)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }
            .navigationTitle("Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func labMetrics(for panel: LabPanel) -> [TrendMetric] {
        LabBiomarker.forPanel(panel, sex: profileSex)
            .flatMap(\.value)
            .filter { $0 != .bloodPressureSystolic && $0 != .bloodPressureDiastolic }
            .map { .lab($0) }
    }

    private func metricToggle(_ metric: TrendMetric) -> some View {
        Toggle(isOn: Binding(
            get: { viewModel.enabledMetrics.contains(metric) },
            set: { isOn in
                var updated = viewModel.enabledMetrics
                if isOn {
                    updated.insert(metric)
                } else {
                    updated.remove(metric)
                }
                viewModel.setEnabledMetrics(updated)
            }
        )) {
            Label(metric.title, systemImage: metric.icon)
        }
    }
}
