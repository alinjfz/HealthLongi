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
        profile.phq9Complete = true
        let vm = AssessmentHubViewModel(profile: profile)

        XCTAssertTrue(vm.phq9Completed)
        XCTAssertFalse(vm.gad7Completed)
        XCTAssertTrue(vm.metabolicCompleted)
        XCTAssertFalse(vm.labDataCompleted)
    }

    @MainActor
    func testAssessmentHubViewModelZeroScoreWithCompletionFlag() {
        let profile = UserProfile(phq9Score: 0, gad7Score: 0)
        profile.phq9Complete = true
        profile.gad7Complete = true
        let vm = AssessmentHubViewModel(profile: profile)

        XCTAssertTrue(vm.phq9Completed)
        XCTAssertTrue(vm.gad7Completed)
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

    func testWeightUnitConversion() {
        XCTAssertEqual(WeightUnit.lb.toKg(154), 69.85, accuracy: 0.1)
        XCTAssertEqual(HeightUnit.toCm(feet: 5, inches: 9), 175.26, accuracy: 0.1)
    }

    // MARK: - LabResults

    func testLabResultsEncodingDecoding() throws {
        let original = LabResults(
            ast: 25,
            alt: 30,
            alp: 70,
            ft4: 16,
            esr: 8,
            vitaminB12: 350,
            folate: 12,
            cholesterol: 5.2,
            bloodSugar: 5.5,
            hba1c: 5.7,
            bloodPressureSystolic: 120,
            bloodPressureDiastolic: 80,
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LabResults.self, from: data)

        XCTAssertEqual(decoded.ast, original.ast)
        XCTAssertEqual(decoded.ft4, original.ft4)
        XCTAssertEqual(decoded.vitaminB12, original.vitaminB12)
        XCTAssertEqual(decoded.cholesterol, original.cholesterol)
        XCTAssertEqual(decoded.bloodPressureSystolic, original.bloodPressureSystolic)
    }

    func testLabReportOCRParsing() {
        let text = "ALT 32 U/L\nVitamin B12 450\nHbA1c 5.6%"
        let parsed = LabReportOCRService.parseReportText(text)
        XCTAssertFalse(parsed.isEmpty)
    }

    // MARK: - Privacy

    func testAbstractedRiskProfileExcludesLabAndGeneticsKeys() throws {
        let profile = AbstractedRiskProfile(
            cardioRisk: .moderate,
            mentalHealth: .mild,
            metabolic: .low,
            correlations: ["test"]
        )
        let json = try JSONEncoder().encode(profile)
        let text = String(data: json, encoding: .utf8) ?? ""

        XCTAssertFalse(text.contains("cholesterol"))
        XCTAssertFalse(text.contains("labResults"))
        XCTAssertFalse(text.contains("genetics"))
        XCTAssertFalse(text.contains("vitaminB12"))
    }

    func testGLMPromptDoesNotIncludeLabFields() {
        let prompt = GLMPrompts.userPrompt(for: .placeholder)
        XCTAssertFalse(prompt.contains("cholesterol"))
        XCTAssertFalse(prompt.contains("BRCA"))
    }

    // MARK: - Genetics

    func testGeneticsCatalogHighlighting() {
        var genetics = GeneticsProfile.empty
        genetics.familyBreastOvarian = true
        let highlights = GeneticsCatalog.highlighted(for: genetics)
        XCTAssertTrue(highlights.contains { $0.id == "brca" })
    }

    // MARK: - HealthKit trends mock

    func testMockDailySeriesGeneration() {
        let points = MockHealthDataProvider.generateSeries(for: .steps, days: 7, base: WeeklyHealthSnapshot(
            averageDailySteps: 5000,
            priorAverageDailySteps: 5000,
            fetchedAt: .now
        ))
        XCTAssertEqual(points.count, 7)
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
