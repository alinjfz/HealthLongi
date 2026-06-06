import Foundation

@MainActor
@Observable
final class TrendsViewModel {
    private let healthDataProvider: any HealthDataProviding

    var selectedMetric: HealthKitMetric = .steps
    var selectedRange: TrendRange = .days30
    var dataPoints: [DailyDataPoint] = []
    var isLoading = false
    var errorMessage: String?

    init(healthDataProvider: any HealthDataProviding) {
        self.healthDataProvider = healthDataProvider
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await healthDataProvider.requestAuthorization()
            dataPoints = try await healthDataProvider.fetchDailySeries(for: selectedMetric, days: selectedRange.days)
        } catch {
            dataPoints = []
            errorMessage = "Could not load HealthKit trends."
        }
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
