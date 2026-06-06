import XCTest
@testable import HealthLongi

final class PersonalHealthContextBuilderTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testFullMockProfileHasSevenScreeningEntries() {
        let profile = fullMockProfile()
        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.averageDailySteps = 6500
        snapshot.averageSleepHours = 7.5
        snapshot.averageRestingHeartRate = 68
        snapshot.fetchedAt = referenceDate

        let context = PersonalHealthContextBuilder.build(
            profile: profile,
            snapshot: snapshot,
            signals: [],
            at: referenceDate
        )

        XCTAssertEqual(context.screeningSnapshot.count, 6)
    }

    func testLifestyleSnapshotPopulatedFromWeeklyHealthSnapshot() {
        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.averageDailySteps = 8200
        snapshot.averageSleepHours = 7.2
        snapshot.averageRestingHeartRate = 65
        snapshot.fetchedAt = referenceDate

        let context = PersonalHealthContextBuilder.build(
            profile: UserProfile(onboardingComplete: true),
            snapshot: snapshot,
            signals: [],
            at: referenceDate
        )

        XCTAssertEqual(context.lifestyleSnapshot.averageDailySteps, 8200)
        XCTAssertEqual(context.lifestyleSnapshot.averageSleepHours, 7.2)
        XCTAssertEqual(context.lifestyleSnapshot.averageRestingHeartRate, 65)
    }

    func testLabFlagsPopulatedFromEvaluator() {
        var labs = LabResults(lastUpdated: referenceDate)
        labs.vitaminD = 18
        let profile = UserProfile(onboardingComplete: true, labResults: labs)

        let context = PersonalHealthContextBuilder.build(
            profile: profile,
            snapshot: .empty,
            signals: [],
            at: referenceDate
        )

        XCTAssertEqual(context.labFlags.count, 1)
        XCTAssertEqual(context.labFlags[0].biomarker, .vitaminD)
    }

    func testActiveSignalsCopiedFromEngineOutput() {
        let signal = HealthSignal(
            id: "sleep_anxiety",
            kind: .correlation,
            title: "Test",
            detail: "Detail",
            evidence: [EvidenceItem(source: .screening, label: "GAD-7", value: "12")],
            suggestedQuestions: [],
            severity: .watch,
            bodyRegion: .brain,
            createdAt: referenceDate
        )

        let context = PersonalHealthContextBuilder.build(
            profile: UserProfile(onboardingComplete: true),
            snapshot: .empty,
            signals: [signal],
            at: referenceDate
        )

        XCTAssertEqual(context.activeSignals.count, 1)
        XCTAssertEqual(context.activeSignals[0].id, "sleep_anxiety")
    }

    func testJSONRoundTripOnUserProfile() throws {
        let profile = fullMockProfile()
        var snapshot = WeeklyHealthSnapshot.empty
        snapshot.fetchedAt = referenceDate

        _ = PersonalHealthContextBuilder.rebuild(profile: profile, snapshot: snapshot, at: referenceDate)

        let data = try JSONEncoder().encode(profile.personalHealthContext!)
        let decoded = try JSONDecoder().decode(PersonalHealthContext.self, from: data)

        XCTAssertEqual(decoded.screeningSnapshot.count, 6)
        XCTAssertEqual(decoded.lastUpdated, referenceDate)
    }

    func testRebuildUpdatesLastUpdated() {
        let profile = UserProfile(onboardingComplete: true)
        let updated = PersonalHealthContextBuilder.rebuild(
            profile: profile,
            snapshot: .empty,
            at: referenceDate
        )

        XCTAssertEqual(updated.lastUpdated, referenceDate)
        XCTAssertEqual(profile.personalHealthContext?.lastUpdated, referenceDate)
    }

    private func fullMockProfile() -> UserProfile {
        UserProfile(
            onboardingComplete: true,
            phq9Score: 8,
            gad7Score: 6,
            who5Score: 18,
            pss10Score: 14,
            auditCScore: 2,
            phq15Score: 5,
            phq9Complete: true,
            gad7Complete: true,
            who5Complete: true,
            pss10Complete: true,
            auditCComplete: true,
            phq15Complete: true
        )
    }
}
