import SwiftUI
import Charts

struct HealthMetricChart: View {
    let metric: HealthKitMetric
    let dataPoints: [DailyDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dataPoints.isEmpty {
                Text("No trend data available for this metric yet.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(NHSTheme.primaryBlue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(NHSTheme.primaryBlue.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 220)
            }
        }
        .nhsCard()
    }
}

struct MetricTrendCard: View {
    let metric: HealthKitMetric
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: metric.icon)
                .foregroundStyle(isSelected ? .white : NHSTheme.primaryBlue)
                .frame(width: 36, height: 36)
                .background(isSelected ? NHSTheme.primaryBlue : NHSTheme.primaryBlue.opacity(0.12))
                .clipShape(Circle())

            Text(metric.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? NHSTheme.primaryBlue : NHSTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? NHSTheme.lightBlue : Color.clear)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(isSelected ? NHSTheme.primaryBlue : NHSTheme.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }
}
