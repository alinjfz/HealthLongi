import Foundation

@MainActor
@Observable
final class TrendsViewModel {
    private let healthDataProvider: any HealthDataProviding

    var enabledMetrics: Set<TrendMetric> = TrendMetricSelectionStore.load()
    var selectedRange: TrendRange = .days30
    var series: [TrendSeriesData] = []
    var isLoading = false
    var errorMessage: String?

    init(healthDataProvider: any HealthDataProviding) {
        self.healthDataProvider = healthDataProvider
    }

    var usesNormalizedAxis: Bool {
        enabledMetrics.count != 1
    }

    var singleMetric: TrendMetric? {
        enabledMetrics.count == 1 ? enabledMetrics.first : nil
    }

    func setEnabledMetrics(_ metrics: Set<TrendMetric>) {
        enabledMetrics = metrics.isEmpty ? TrendMetric.defaultEnabled : metrics
        TrendMetricSelectionStore.save(enabledMetrics)
    }

    func toggleMetric(_ metric: TrendMetric) {
        var updated = enabledMetrics
        if updated.contains(metric) {
            updated.remove(metric)
        } else {
            updated.insert(metric)
        }
        setEnabledMetrics(updated)
    }

    func load(labHistory: [LabResultsSnapshot]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await healthDataProvider.requestAuthorization()
            let cutoff = Calendar.current.date(
                byAdding: .day,
                value: -selectedRange.days,
                to: Calendar.current.startOfDay(for: .now)
            ) ?? .now

            var loadedSeries: [TrendSeriesData] = []
            let sortedMetrics = enabledMetrics.sorted { $0.title < $1.title }

            for (index, metric) in sortedMetrics.enumerated() {
                let points: [TrendDataPoint]
                switch metric {
                case .healthKit(let hkMetric):
                    points = try await loadHealthKitSeries(
                        metric: hkMetric,
                        trendMetric: metric,
                        cutoff: cutoff
                    )
                case .lab(let biomarker):
                    points = loadLabSeries(
                        biomarker: biomarker,
                        trendMetric: metric,
                        history: labHistory,
                        cutoff: cutoff
                    )
                case .bloodPressure:
                    points = loadBloodPressureSeries(
                        history: labHistory,
                        cutoff: cutoff
                    )
                }

                if !points.isEmpty {
                    loadedSeries.append(
                        TrendSeriesData(metric: metric, points: points, colorIndex: index)
                    )
                }
            }

            series = loadedSeries
        } catch {
            series = []
            errorMessage = "Could not load HealthKit trends."
        }
    }

    private func loadHealthKitSeries(
        metric: HealthKitMetric,
        trendMetric: TrendMetric,
        cutoff: Date
    ) async throws -> [TrendDataPoint] {
        let dailyPoints = try await healthDataProvider.fetchDailySeries(
            for: metric,
            days: selectedRange.days
        )

        return dailyPoints
            .filter { $0.date >= cutoff }
            .map { point in
                let status = MetricHealthEvaluator.status(for: metric, value: point.value)
                return TrendDataPoint(
                    date: point.date,
                    rawValue: point.value,
                    status: status,
                    metric: trendMetric,
                    formattedValue: trendMetric.formattedValue(point.value)
                )
            }
    }

    private func loadLabSeries(
        biomarker: LabBiomarker,
        trendMetric: TrendMetric,
        history: [LabResultsSnapshot],
        cutoff: Date
    ) -> [TrendDataPoint] {
        history
            .filter { $0.recordedAt >= cutoff }
            .compactMap { snapshot -> TrendDataPoint? in
                guard let value = LabBiomarkerIO.doubleValue(biomarker, from: snapshot.results) else {
                    return nil
                }
                let status = MetricHealthEvaluator.status(for: biomarker, value: value)
                return TrendDataPoint(
                    date: snapshot.recordedAt,
                    rawValue: value,
                    status: status,
                    metric: trendMetric,
                    formattedValue: trendMetric.formattedValue(value)
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func loadBloodPressureSeries(
        history: [LabResultsSnapshot],
        cutoff: Date
    ) -> [TrendDataPoint] {
        history
            .filter { $0.recordedAt >= cutoff }
            .compactMap { snapshot -> TrendDataPoint? in
                guard let systolic = snapshot.results.bloodPressureSystolic,
                      let diastolic = snapshot.results.bloodPressureDiastolic else {
                    return nil
                }
                let status = MetricHealthEvaluator.bloodPressureStatus(
                    systolic: systolic,
                    diastolic: diastolic
                )
                let metric = TrendMetric.bloodPressure
                let formatted = "\(systolic)/\(diastolic) mmHg"
                return TrendDataPoint(
                    date: snapshot.recordedAt,
                    rawValue: Double(systolic),
                    status: status,
                    metric: metric,
                    formattedValue: formatted
                )
            }
            .sorted { $0.date < $1.date }
    }
}

enum TrendRange: String, CaseIterable, Identifiable {
    case days7
    case days30
    case days90

    var id: String { rawValue }

    var title: String {
        switch self {
        case .days7: "7D"
        case .days30: "30D"
        case .days90: "90D"
        }
    }

    var days: Int {
        switch self {
        case .days7: 7
        case .days30: 30
        case .days90: 90
        }
    }
}
