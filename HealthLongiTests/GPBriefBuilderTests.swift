import XCTest
@testable import HealthLongi

final class GPBriefBuilderTests: XCTestCase {
    func testMockPHCHasScreeningScoresWithBands() {
        let profile = sampleProfile()
        let context = sampleContext(profile: profile)

        let brief = GPBriefBuilder.build(profile: profile, context: context)

        XCTAssertFalse(brief.screeningScores.isEmpty)
        XCTAssertEqual(brief.screeningScores.first?.kind, .phq9)
        XCTAssertEqual(brief.screeningScores.first?.band, "Mild")
    }

    func testOnlyAbnormalLabsInCollapsedSection() {
        let profile = sampleProfile()
        var context = sampleContext(profile: profile)
        context.labFlags = [
            LabFlag(biomarker: .vitaminD, value: 18, reference: LabBiomarker.vitaminD.referenceRange!, direction: .below, flaggedAt: .now)
        ]

        let brief = GPBriefBuilder.build(profile: profile, context: context)

        XCTAssertEqual(brief.abnormalLabs.count, 1)
        XCTAssertNotNil(brief.allLabResults)
    }

    func testMoodConcernPrioritisesMoodSignals() {
        let profile = sampleProfile()
        var context = sampleContext(profile: profile)
        context.appointmentPrep = AppointmentPrepContext(
            selectedConcerns: [GPConcern.mood.rawValue],
            freeTextNotes: "",
            updatedAt: .now
        )
        context.activeSignals = [
            makeSignal(id: "lipid_flag", title: "LDL", severity: .discussWithGP),
            makeSignal(id: "sleep_anxiety", title: "Sleep anxiety", severity: .watch)
        ]

        let brief = GPBriefBuilder.build(profile: profile, context: context)

        XCTAssertEqual(brief.discussionTopics.first?.signalID, "sleep_anxiety")
    }

    func testEmptyPHCStillGeneratesWithDisclaimer() {
        let profile = UserProfile(onboardingComplete: true)
        let context = PersonalHealthContext.empty

        let brief = GPBriefBuilder.build(profile: profile, context: context)

        XCTAssertFalse(brief.disclaimer.isEmpty)
        XCTAssertTrue(brief.discussionTopics.isEmpty)
    }

    func testGeneticsLabelledFamilyHistoryDemo() {
        var profile = sampleProfile()
        var genetics = GeneticsProfile.empty
        genetics.quizCompleted = true
        genetics.familyHeart = true
        profile.geneticsProfile = genetics

        let brief = GPBriefBuilder.build(profile: profile, context: sampleContext(profile: profile))

        XCTAssertEqual(brief.geneticsNote, "Family history / demo genetics data included for context only.")
    }

    private func sampleProfile() -> UserProfile {
        var labs = LabResults(lastUpdated: .now)
        labs.vitaminD = 18
        return UserProfile(
            onboardingComplete: true,
            phq9Score: 8,
            gad7Score: 6,
            phq9Complete: true,
            gad7Complete: true,
            labResults: labs
        )
    }

    private func sampleContext(profile: UserProfile) -> PersonalHealthContext {
        PersonalHealthContext(
            lastUpdated: .now,
            activeSignals: [makeSignal(id: "sleep_anxiety", title: "Sleep", severity: .watch)],
            screeningSnapshot: [
                ScreeningSnapshot(kind: .phq9, score: 8, maxScore: 27, band: "Mild", completedAt: .now)
            ],
            lifestyleSnapshot: LifestyleSnapshot.from(.empty),
            labFlags: LabFlagEvaluator.evaluate(labs: profile.labResults ?? .empty),
            appointmentPrep: nil,
            weeklyInsightHistory: [],
            completenessScore: 40
        )
    }

    private func makeSignal(id: String, title: String, severity: HealthSignal.Severity) -> HealthSignal {
        HealthSignal(
            id: id,
            kind: .correlation,
            title: title,
            detail: "Detail",
            evidence: [EvidenceItem(source: .screening, label: "Test", value: "1")],
            suggestedQuestions: ["Question?"],
            severity: severity,
            bodyRegion: nil,
            createdAt: .now
        )
    }
}
