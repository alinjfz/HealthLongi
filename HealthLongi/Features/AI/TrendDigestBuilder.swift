import Foundation

enum TrendDigestBuilder {
    static func build(from series: [HealthKitMetric: [DailyDataPoint]]) -> TrendDigest {
        TrendDigest(
            steps: digest(series[.steps]),
            sleep: digest(series[.sleep]),
            restingHeartRate: digest(series[.restingHeartRate])
        )
    }

    private static func digest(_ points: [DailyDataPoint]?) -> TrendMetricDigest? {
        guard let points, points.count >= 7 else { return nil }

        let sorted = points.sorted { $0.date < $1.date }
        let midpoint = sorted.count / 2
        let prior = sorted.prefix(midpoint).map(\.value)
        let recent = sorted.suffix(sorted.count - midpoint).map(\.value)

        guard !prior.isEmpty, !recent.isEmpty else { return nil }

        let priorAvg = prior.reduce(0, +) / Double(prior.count)
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        guard priorAvg > 0 else { return nil }

        let change = ((recentAvg - priorAvg) / priorAvg) * 100
        let direction: TrendDirection
        if change > 8 { direction = .rising }
        else if change < -8 { direction = .falling }
        else { direction = .stable }

        return TrendMetricDigest(
            recentAverage: recentAvg,
            priorAverage: priorAvg,
            changePercent: change,
            direction: direction,
            dayCount: sorted.count
        )
    }
}
