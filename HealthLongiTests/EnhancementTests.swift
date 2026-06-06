import XCTest
@testable import HealthLongi

final class EnhancementTests: XCTestCase {

    // MARK: - SmokingStatus

    func testSmokingStatusHasFrequency() {
        XCTAssertFalse(SmokingStatus.never.hasFrequency)
        XCTAssertFalse(SmokingStatus.former.hasFrequency)
        XCTAssertFalse(SmokingStatus.currentRegular.hasFrequency)
        XCTAssertTrue(SmokingStatus.currentOccasional.hasFrequency)
        XCTAssertFalse(SmokingStatus.vapingRegular.hasFrequency)
        XCTAssertTrue(SmokingStatus.vapingOccasional.hasFrequency)
    }

    func testSmokingStatusLegacyMigration() {
        XCTAssertEqual(SmokingStatus.fromStored("current"), .currentRegular)
        XCTAssertEqual(SmokingStatus.fromStored("never"), .never)
    }

    func testSmokingStatusDisplayNames() {
        XCTAssertEqual(SmokingStatus.currentRegular.displayName, "Current smoker (daily)")
        XCTAssertEqual(SmokingStatus.vapingOccasional.displayName, "Vaping (occasionally)")
    }

    // MARK: - AssessmentHubViewModel

    @MainActor
    func testAssessmentHubViewModelCompletionTracking() {
        let profile = UserProfile(phq9Score: 5, gad7Score: 0, bmi: 24, physicalActivityMinutes: 90)
        let vm = AssessmentHubViewModel(profile: profile)

        XCTAssertTrue(vm.phq9Completed)
        XCTAssertFalse(vm.gad7Completed)
        XCTAssertTrue(vm.metabolicCompleted)
        XCTAssertFalse(vm.labDataCompleted)
    }

    @MainActor
    func testAssessmentHubViewModelEmptyProfile() {
        let vm = AssessmentHubViewModel(profile: nil)
        XCTAssertFalse(vm.phq9Completed)
        XCTAssertFalse(vm.gad7Completed)
        XCTAssertFalse(vm.metabolicCompleted)
    }

    // MARK: - BMI Calculator

    func testBMICalculationNormal() {
        let result = BMICalculatorResult.calculate(weightKg: 70, heightCm: 175)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.category, .normal)
        XCTAssertEqual(result?.bmi ?? 0, 22.9, accuracy: 0.1)
    }

    func testBMICalculationOverweight() {
        let result = BMICalculatorResult.calculate(weightKg: 85, heightCm: 170)
        XCTAssertEqual(result?.category, .overweight)
    }

    func testBMICalculationInvalidInput() {
        XCTAssertNil(BMICalculatorResult.calculate(weightKg: 0, heightCm: 175))
        XCTAssertNil(BMICalculatorResult.calculate(weightKg: 70, heightCm: -10))
    }

    // MARK: - LabResults

    func testLabResultsEncodingDecoding() throws {
        let original = LabResults(
            cholesterol: 5.2,
            bloodPressureSystolic: 120,
            bloodPressureDiastolic: 80,
            bloodSugar: 5.5,
            hba1c: 5.7,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LabResults.self, from: data)

        XCTAssertEqual(decoded.cholesterol, original.cholesterol)
        XCTAssertEqual(decoded.bloodPressureSystolic, original.bloodPressureSystolic)
        XCTAssertEqual(decoded.bloodPressureDiastolic, original.bloodPressureDiastolic)
        XCTAssertEqual(decoded.bloodSugar, original.bloodSugar)
        XCTAssertEqual(decoded.hba1c, original.hba1c)
    }

    // MARK: - MotivationalQuotes

    func testMotivationalQuotesRandomization() {
        let quote = MotivationalQuotes.random()
        XCTAssertFalse(quote.quote.isEmpty)
        XCTAssertTrue(MotivationalQuotes.all.contains { $0.quote == quote.quote })
    }

    func testMotivationalQuotesCategoryFilter() {
        let quote = MotivationalQuotes.random(for: .mental)
        XCTAssertEqual(quote.category, .mental)
    }

    // MARK: - HealthTips

    func testHealthTipsForHighMentalRiskProfile() {
        let profile = AbstractedRiskProfile(
            cardioRisk: .low,
            mentalHealth: .highAnxiety,
            metabolic: .low,
            correlations: []
        )
        let tips = HealthTips.forProfile(profile)
        XCTAssertTrue(tips.contains { $0.category == .mental })
    }

    func testHealthTipsForLowRiskProfile() {
        let profile = AbstractedRiskProfile.placeholder
        let tips = HealthTips.forProfile(profile)
        XCTAssertFalse(tips.isEmpty)
    }

    // MARK: - GDPR confirmation

    func testGDPRConfirmationValidation() {
        XCTAssertFalse(isGDPRConfirmationValid("delete"))
        XCTAssertFalse(isGDPRConfirmationValid(""))
        XCTAssertTrue(isGDPRConfirmationValid("DELETE"))
        XCTAssertTrue(isGDPRConfirmationValid("  DELETE  "))
    }
}

/// Mirrors GDPRDeleteView confirmation logic for unit testing.
private func isGDPRConfirmationValid(_ text: String) -> Bool {
    text.trimmingCharacters(in: .whitespaces) == "DELETE"
}
