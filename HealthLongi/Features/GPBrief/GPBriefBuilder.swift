import Foundation

struct GPBriefBuilder {
    static func build(
        profile: UserProfile,
        context: PersonalHealthContext,
        suggestedQuestions: [String] = []
    ) -> GPVisitBrief {
        let prep = context.appointmentPrep
        let selectedConcerns = prep?.selectedConcerns ?? []
        let topics = orderedTopics(from: context.activeSignals, concerns: selectedConcerns)
        let questions = suggestedQuestions.isEmpty
            ? context.activeSignals.flatMap(\.suggestedQuestions)
            : suggestedQuestions

        return GPVisitBrief(
            reasonForVisit: prep?.freeTextNotes.isEmpty == false
                ? prep!.freeTextNotes
                : defaultReason(concerns: selectedConcerns),
            discussionTopics: topics,
            screeningScores: context.screeningSnapshot,
            physicalMeasures: context.lifestyleSnapshot,
            abnormalLabs: context.labFlags,
            allLabResults: profile.labResults,
            suggestedQuestions: Array(questions.prefix(5)),
            geneticsNote: geneticsNote(from: profile),
            dataSourcesNote: dataSourcesNote(profile: profile, context: context),
            completenessPercent: context.completenessScore,
            disclaimer: GPVisitBrief.standardDisclaimer,
            generatedAt: .now
        )
    }

    private static func orderedTopics(
        from signals: [HealthSignal],
        concerns: [String]
    ) -> [GPBriefSignalTopic] {
        guard !concerns.isEmpty else {
            return signals.map(topic(from:))
        }

        let concernSet = Set(concerns)
        let matching = signals.filter { signal in
            GPConcern.allCases.contains { concern in
                concernSet.contains(concern.rawValue) && concern.matchingSignalIDs.contains(signal.id)
            }
        }
        let others = signals.filter { signal in !matching.contains(where: { $0.id == signal.id }) }
        return (matching + others).map(topic(from:))
    }

    private static func topic(from signal: HealthSignal) -> GPBriefSignalTopic {
        GPBriefSignalTopic(
            signalID: signal.id,
            title: signal.title,
            severity: severityLabel(signal.severity),
            evidenceSummary: signal.evidence.map { "\($0.label): \($0.value)" }.joined(separator: "; ")
        )
    }

    private static func severityLabel(_ severity: HealthSignal.Severity) -> String {
        switch severity {
        case .discussWithGP: "Discuss with GP"
        case .watch: "Worth watching"
        case .info: "Information"
        }
    }

    private static func defaultReason(concerns: [String]) -> String {
        guard !concerns.isEmpty else { return "Routine GP visit — sharing recent health data." }
        let labels = concerns.compactMap { GPConcern(rawValue: $0)?.label }
        return "I'd like to discuss: \(labels.joined(separator: ", "))."
    }

    private static func geneticsNote(from profile: UserProfile) -> String? {
        guard let genetics = profile.geneticsProfile, genetics.hasAnyValue else { return nil }
        return "Family history / demo genetics data included for context only."
    }

    private static func dataSourcesNote(profile: UserProfile, context: PersonalHealthContext) -> String {
        var sources: [String] = []
        if !context.screeningSnapshot.isEmpty { sources.append("validated screenings") }
        if context.lifestyleSnapshot.averageDailySteps > 0 { sources.append("HealthKit averages") }
        if !context.labFlags.isEmpty { sources.append("lab results") }
        if profile.geneticsProfile?.hasAnyValue == true { sources.append("family history (demo)") }
        return sources.isEmpty
            ? "Limited data available — completeness \(context.completenessScore)%."
            : "Based on \(sources.joined(separator: ", ")). Completeness \(context.completenessScore)%."
    }
}

private extension GeneticsProfile {
    var hasAnyValue: Bool {
        quizCompleted || mockUploadCompleted || familyCancer || familyHeart || familyKidney
            || familyNeuro || familyMetabolic || familyBreastOvarian || familyColon || familyDiabetes
    }
}
