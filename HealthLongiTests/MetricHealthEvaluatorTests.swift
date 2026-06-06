import XCTest
@testable import HealthLongi

final class MetricHealthEvaluatorTests: XCTestCase {
    func testStepsThresholds() {
        XCTAssertEqual(MetricHealthEvaluator.status(for: .steps, value: 8000), .good)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .steps, value: 5000), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .steps, value: 3000), .poor)
    }

    func testRestingHeartRateInvertsLowerIsBetter() {
        XCTAssertEqual(MetricHealthEvaluator.status(for: .restingHeartRate, value: 65), .good)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .restingHeartRate, value: 75), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .restingHeartRate, value: 85), .poor)
    }

    func testOxygenSaturationThresholds() {
        XCTAssertEqual(MetricHealthEvaluator.status(for: .oxygenSaturation, value: 98), .good)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .oxygenSaturation, value: 92), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .oxygenSaturation, value: 88), .poor)
    }

    func testLabLDLThresholds() {
        XCTAssertEqual(MetricHealthEvaluator.status(for: .ldlCholesterol, value: 2.5), .good)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .ldlCholesterol, value: 3.5), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .ldlCholesterol, value: 4.5), .poor)
    }

    func testLabHbA1cThresholds() {
        XCTAssertEqual(MetricHealthEvaluator.status(for: .hba1c, value: 5.4), .good)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .hba1c, value: 6.2), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .hba1c, value: 7.0), .poor)
    }

    func testLabGlucoseThresholds() {
        XCTAssertEqual(MetricHealthEvaluator.status(for: .bloodSugar, value: 5.0), .good)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .bloodSugar, value: 6.0), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.status(for: .bloodSugar, value: 8.0), .poor)
    }

    func testBloodPressureCombinedStatus() {
        XCTAssertEqual(MetricHealthEvaluator.bloodPressureStatus(systolic: 118, diastolic: 76), .good)
        XCTAssertEqual(MetricHealthEvaluator.bloodPressureStatus(systolic: 130, diastolic: 85), .moderate)
        XCTAssertEqual(MetricHealthEvaluator.bloodPressureStatus(systolic: 150, diastolic: 95), .poor)
    }

    func testHealthStatusNormalizedValues() {
        XCTAssertEqual(HealthStatus.good.rawValue, 1)
        XCTAssertEqual(HealthStatus.moderate.rawValue, 0.5)
        XCTAssertEqual(HealthStatus.poor.rawValue, 0)
    }
}

final class LabResultsSnapshotTests: XCTestCase {
    func testEncodeDecodeRoundTrip() throws {
        var results = LabResults(lastUpdated: .now)
        results.cholesterol = 4.8
        results.bloodPressureSystolic = 120
        results.bloodPressureDiastolic = 80

        let snapshot = LabResultsSnapshot(
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000),
            results: results
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(LabResultsSnapshot.self, from: data)

        XCTAssertEqual(decoded.recordedAt, snapshot.recordedAt)
        XCTAssertEqual(decoded.results.cholesterol, 4.8)
        XCTAssertEqual(decoded.results.bloodPressureSystolic, 120)
        XCTAssertEqual(decoded.results.bloodPressureDiastolic, 80)
    }

    func testMigrationSeedsFromCurrentLabResults() {
        var results = LabResults(lastUpdated: Date(timeIntervalSince1970: 1_700_000_000))
        results.ldlCholesterol = 3.2

        let profile = UserProfile(labResults: results)
        XCTAssertTrue(profile.labResultsHistory.isEmpty)

        profile.migrateLabResultsHistoryIfNeeded()

        XCTAssertEqual(profile.labResultsHistory.count, 1)
        XCTAssertEqual(profile.labResultsHistory.first?.results.ldlCholesterol, 3.2)
        XCTAssertEqual(
            profile.labResultsHistory.first?.recordedAt,
            Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    func testMigrationDoesNotDuplicateExistingHistory() {
        var results = LabResults(lastUpdated: .now)
        results.hba1c = 5.6
        let profile = UserProfile(labResults: results)
        profile.labResultsHistory = [
            LabResultsSnapshot(recordedAt: .now, results: results)
        ]

        profile.migrateLabResultsHistoryIfNeeded()

        XCTAssertEqual(profile.labResultsHistory.count, 1)
    }
}

final class TrendMetricSelectionStoreTests: XCTestCase {
    func testDefaultEnabledMetrics() {
        UserDefaults.standard.removeObject(forKey: "trendEnabledMetrics")
        let loaded = TrendMetricSelectionStore.load()
        XCTAssertTrue(loaded.contains(.healthKit(.steps)))
        XCTAssertTrue(loaded.contains(.healthKit(.sleep)))
        XCTAssertTrue(loaded.contains(.bloodPressure))
    }

    func testSaveAndLoadRoundTrip() {
        let metrics: Set<TrendMetric> = [.healthKit(.hrv), .lab(.vitaminD)]
        TrendMetricSelectionStore.save(metrics)
        let loaded = TrendMetricSelectionStore.load()
        XCTAssertEqual(loaded, metrics)
        UserDefaults.standard.removeObject(forKey: "trendEnabledMetrics")
    }
}
