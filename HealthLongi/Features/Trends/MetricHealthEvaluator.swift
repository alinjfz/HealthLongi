import Foundation
import SwiftUI

enum HealthStatus: Double, CaseIterable, Sendable {
    case poor = 0
    case moderate = 0.5
    case good = 1

    var label: String {
        switch self {
        case .poor: "Poor"
        case .moderate: "Moderate"
        case .good: "Good"
        }
    }

    var color: Color {
        switch self {
        case .poor: .red
        case .moderate: .orange
        case .good: .green
        }
    }
}

struct MetricHealthEvaluator {
    static func status(for metric: HealthKitMetric, value: Double) -> HealthStatus {
        switch metric {
        case .steps:
            if value >= 7000 { return .good }
            if value >= 4000 { return .moderate }
            return .poor
        case .restingHeartRate:
            if value <= 70 { return .good }
            if value <= 80 { return .moderate }
            return .poor
        case .sleep:
            if (7...9).contains(value) { return .good }
            if value >= 6 { return .moderate }
            return .poor
        case .activeEnergy:
            if value >= 400 { return .good }
            if value >= 200 { return .moderate }
            return .poor
        case .distance:
            return .moderate
        case .hrv:
            if value >= 40 { return .good }
            if value >= 25 { return .moderate }
            return .poor
        case .oxygenSaturation:
            if value >= 95 { return .good }
            if value >= 90 { return .moderate }
            return .poor
        case .bodyMass:
            return .moderate
        case .height:
            return .moderate
        case .bmi:
            if value < 25 { return .good }
            if value < 30 { return .moderate }
            return .poor
        case .exerciseMinutes:
            if value >= 150 { return .good }
            if value >= 75 { return .moderate }
            return .poor
        case .bodyFat:
            if value <= 24 { return .good }
            if value <= 32 { return .moderate }
            return .poor
        case .mindfulMinutes:
            if value >= 10 { return .good }
            if value >= 5 { return .moderate }
            return .poor
        }
    }

    static func status(for biomarker: LabBiomarker, value: Double) -> HealthStatus {
        switch biomarker {
        case .cholesterol:
            if value < 5.0 { return .good }
            if value < 6.0 { return .moderate }
            return .poor
        case .ldlCholesterol:
            if value < 3.0 { return .good }
            if value < 4.0 { return .moderate }
            return .poor
        case .hdlCholesterol:
            if value >= 1.2 { return .good }
            if value >= 1.0 { return .moderate }
            return .poor
        case .triglycerides:
            if value < 1.7 { return .good }
            if value < 2.3 { return .moderate }
            return .poor
        case .bloodSugar:
            if (3.9...5.5).contains(value) { return .good }
            if value < 7.0 { return .moderate }
            return .poor
        case .hba1c:
            if value < 6.0 { return .good }
            if value < 6.5 { return .moderate }
            return .poor
        case .vitaminD:
            if value >= 50 { return .good }
            if value >= 25 { return .moderate }
            return .poor
        case .tsh:
            if (0.4...4.0).contains(value) { return .good }
            if (0.2...5.0).contains(value) { return .moderate }
            return .poor
        case .egfr:
            if value >= 90 { return .good }
            if value >= 60 { return .moderate }
            return .poor
        case .crp:
            if value < 1.0 { return .good }
            if value < 3.0 { return .moderate }
            return .poor
        default:
            return .moderate
        }
    }

    static func bloodPressureStatus(systolic: Int, diastolic: Int) -> HealthStatus {
        if systolic < 120 && diastolic < 80 { return .good }
        if systolic < 140 && diastolic < 90 { return .moderate }
        return .poor
    }
}

struct TrendDataPoint: Identifiable, Sendable, Equatable {
    let date: Date
    let rawValue: Double
    let status: HealthStatus
    let metric: TrendMetric
    let formattedValue: String

    var id: String { "\(metric.id)-\(date.timeIntervalSince1970)" }
}

struct TrendSeriesData: Identifiable, Sendable {
    let metric: TrendMetric
    let points: [TrendDataPoint]
    let colorIndex: Int

    var id: String { metric.id }

    var color: Color {
        metric.chartColor(index: colorIndex)
    }
}

extension TrendMetric {
    func formattedValue(_ rawValue: Double) -> String {
        switch self {
        case .bloodPressure:
            return String(format: "%.0f mmHg", rawValue)
        case .healthKit(let metric):
            switch metric {
            case .steps, .mindfulMinutes, .exerciseMinutes:
                return String(format: "%.0f %@", rawValue, unitLabel)
            case .sleep:
                return SleepDurationFormatting.format(hours: rawValue)
            case .oxygenSaturation, .bodyFat:
                return String(format: "%.0f%%", rawValue)
            case .distance:
                return String(format: "%.1f %@", rawValue, unitLabel)
            default:
                return String(format: "%.1f %@", rawValue, unitLabel)
            }
        case .lab(let biomarker):
            if biomarker.isIntegerField {
                return "\(Int(rawValue)) \(unitLabel)"
            }
            return String(format: "%.1f %@", rawValue, unitLabel)
        }
    }
}
