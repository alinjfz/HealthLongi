import Foundation
import SwiftUI

enum TrendDisplayStyle {
    case line
    case point
}

enum TrendMetric: Hashable, Identifiable, Sendable {
    case healthKit(HealthKitMetric)
    case lab(LabBiomarker)
    case bloodPressure

    var id: String {
        switch self {
        case .healthKit(let metric): "hk:\(metric.rawValue)"
        case .lab(let biomarker): "lab:\(biomarker.rawValue)"
        case .bloodPressure: "bloodPressure"
        }
    }

    static func from(storageKey: String) -> TrendMetric? {
        if storageKey == "bloodPressure" { return .bloodPressure }
        if storageKey.hasPrefix("hk:") {
            let raw = String(storageKey.dropFirst(3))
            guard let metric = HealthKitMetric(rawValue: raw) else { return nil }
            return .healthKit(metric)
        }
        if storageKey.hasPrefix("lab:") {
            let raw = String(storageKey.dropFirst(4))
            guard let biomarker = LabBiomarker(rawValue: raw) else { return nil }
            return .lab(biomarker)
        }
        return nil
    }

    static var allHealthKitTrendMetrics: [TrendMetric] {
        HealthKitMetric.allCases
            .filter(\.supportsTrendChart)
            .map { .healthKit($0) }
    }

    static var allLabTrendMetrics: [TrendMetric] {
        LabBiomarker.allCases
            .filter { $0 != .bloodPressureSystolic && $0 != .bloodPressureDiastolic }
            .map { .lab($0) }
    }

    static var allCases: [TrendMetric] {
        allHealthKitTrendMetrics + [.bloodPressure] + allLabTrendMetrics
    }

    static let defaultEnabled: Set<TrendMetric> = [
        .healthKit(.steps),
        .healthKit(.sleep),
        .healthKit(.restingHeartRate),
        .healthKit(.oxygenSaturation),
        .bloodPressure
    ]

    var title: String {
        switch self {
        case .healthKit(let metric): metric.title
        case .lab(let biomarker): biomarker.label
        case .bloodPressure: "Blood Pressure"
        }
    }

    var icon: String {
        switch self {
        case .healthKit(let metric): metric.icon
        case .lab(let biomarker): biomarker.trendIcon
        case .bloodPressure: "waveform.path.ecg"
        }
    }

    var unitLabel: String {
        switch self {
        case .healthKit(let metric): metric.unitLabel
        case .lab(let biomarker): biomarker.unit
        case .bloodPressure: "mmHg"
        }
    }

    var displayStyle: TrendDisplayStyle {
        switch self {
        case .healthKit(let metric):
            switch metric {
            case .oxygenSaturation, .bodyMass: .point
            default: .line
            }
        case .lab, .bloodPressure: .point
        }
    }

    var isContinuous: Bool {
        displayStyle == .line
    }

    func chartColor(index: Int) -> Color {
        let palette: [Color] = [
            NHSTheme.primaryBlue,
            .purple,
            .teal,
            .orange,
            .pink,
            .indigo,
            .mint,
            .brown,
            .cyan
        ]
        return palette[index % palette.count]
    }
}

private extension LabBiomarker {
    var trendIcon: String {
        switch category {
        case .liver: "cross.case.fill"
        case .thyroid: "thermometer"
        case .inflammation: "flame"
        case .vitamins: "pill.fill"
        case .lipids: "drop.fill"
        case .metabolic: "chart.line.uptrend.xyaxis"
        case .kidneyBP: "heart.text.square"
        case .heart: "heart.fill"
        case .hormones: "waveform.path.ecg"
        case .sleepMinerals: "moon.fill"
        case .cbc, .hematology: "drop.circle"
        case .recovery: "figure.run"
        case .fitnessHormones: "figure.strengthtraining.traditional"
        }
    }
}

enum TrendMetricSelectionStore {
    private static let storageKey = "trendEnabledMetrics"

    static func load() -> Set<TrendMetric> {
        guard let keys = UserDefaults.standard.stringArray(forKey: storageKey), !keys.isEmpty else {
            return TrendMetric.defaultEnabled
        }
        let metrics = Set(keys.compactMap(TrendMetric.from(storageKey:)))
        return metrics.isEmpty ? TrendMetric.defaultEnabled : metrics
    }

    static func save(_ metrics: Set<TrendMetric>) {
        UserDefaults.standard.set(metrics.map(\.id), forKey: storageKey)
    }
}
