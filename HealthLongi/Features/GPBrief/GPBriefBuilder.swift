import Foundation

struct GPBriefBuilder {
    static func build(
        profile: UserProfile,
        assessment: RiskAssessment?,
        aiSummary: AISummaryResult?,
        snapshot: WeeklyHealthSnapshot?,
        prep: AppointmentPrepContext?
    ) -> GPVisitBrief {
        let riskProfile = assessment?.abstractedProfile ?? .placeholder
        let labSignals = riskProfile.labSignals
        let lifestyle = LifestyleSnapshot.from(snapshot ?? .empty)
        let labFlags = LabFlagEvaluator.evaluate(labs: profile.labResults ?? .empty)
        let allTopics = buildTopics(
            profile: profile,
            riskProfile: riskProfile,
            labSignals: labSignals,
            lifestyle: lifestyle,
            labFlags: labFlags,
            aiSummary: aiSummary,
            correlations: riskProfile.correlations
        )
        let selectedConcerns = prep?.selectedConcerns ?? []
        let topics = orderedTopics(allTopics, concerns: selectedConcerns)

        return GPVisitBrief(
            reasonForVisit: prep?.freeTextNotes.isEmpty == false
                ? prep!.freeTextNotes
                : defaultReason(concerns: selectedConcerns),
            discussionTopics: topics,
            screeningScores: screeningEntries(from: profile),
            physicalMeasures: lifestyle,
            abnormalLabs: labFlags,
            allLabResults: profile.labResults,
            suggestedQuestions: suggestedQuestions(
                aiSummary: aiSummary,
                correlations: riskProfile.correlations,
                concerns: selectedConcerns
            ),
            geneticsNote: geneticsNote(from: profile),
            dataSourcesNote: dataSourcesNote(
                profile: profile,
                snapshot: snapshot,
                labFlags: labFlags
            ),
            disclaimer: disclaimer(generatedAt: .now),
            generatedAt: .now
        )
    }

    // MARK: - Discussion topics

    private static func buildTopics(
        profile: UserProfile,
        riskProfile: AbstractedRiskProfile,
        labSignals: LabRiskSignals,
        lifestyle: LifestyleSnapshot,
        labFlags: [LabFlag],
        aiSummary: AISummaryResult?,
        correlations: [String]
    ) -> [GPBriefSignalTopic] {
        var topics: [GPBriefSignalTopic] = []

        if let mood = moodTopic(profile: profile, riskProfile: riskProfile, aiSummary: aiSummary) {
            topics.append(mood)
        }
        if let heart = heartTopic(riskProfile: riskProfile, lifestyle: lifestyle, labSignals: labSignals) {
            topics.append(heart)
        }
        if let labs = labsTopic(labSignals: labSignals, labFlags: labFlags) {
            topics.append(labs)
        }
        if let activity = activityTopic(riskProfile: riskProfile, lifestyle: lifestyle) {
            topics.append(activity)
        }
        if let sleep = sleepTopic(lifestyle: lifestyle, correlations: correlations) {
            topics.append(sleep)
        }
        if let metabolism = metabolismTopic(profile: profile, riskProfile: riskProfile, labSignals: labSignals) {
            topics.append(metabolism)
        }

        return topics
    }

    private static func orderedTopics(
        _ topics: [GPBriefSignalTopic],
        concerns: [String]
    ) -> [GPBriefSignalTopic] {
        guard !concerns.isEmpty else { return topics }

        let concernSet = Set(concerns)
        let matching = topics.filter { concernSet.contains($0.signalID) }
        let others = topics.filter { !concernSet.contains($0.signalID) }
        return matching + others
    }

    private static func moodTopic(
        profile: UserProfile,
        riskProfile: AbstractedRiskProfile,
        aiSummary: AISummaryResult?
    ) -> GPBriefSignalTopic? {
        var evidence: [String] = []

        if profile.isComplete(.phq9) {
            evidence.append("PHQ-9: \(profile.phq9Score)/27 (\(QuestionnaireKind.phq9.band(for: profile.phq9Score)))")
        }
        if profile.isComplete(.gad7) {
            evidence.append("GAD-7: \(profile.gad7Score)/21 (\(QuestionnaireKind.gad7.band(for: profile.gad7Score)))")
        }
        if riskProfile.mentalHealth != .none {
            evidence.append("On-device mental health flag: \(riskProfile.mentalHealth.displayName)")
        }

        let moodWatchItems = aiSummary?.watchItems.filter {
            let area = $0.area.lowercased()
            return area.contains("mood") || area.contains("anxiety") || area.contains("mental")
        } ?? []
        for item in moodWatchItems.prefix(2) {
            evidence.append("\(item.area): \(item.finding)")
        }

        guard !evidence.isEmpty else { return nil }

        return GPBriefSignalTopic(
            signalID: GPConcern.mood.rawValue,
            title: "Mood & mental wellbeing",
            severity: mentalSeverity(riskProfile.mentalHealth),
            evidenceSummary: evidence.joined(separator: "; ")
        )
    }

    private static func heartTopic(
        riskProfile: AbstractedRiskProfile,
        lifestyle: LifestyleSnapshot,
        labSignals: LabRiskSignals
    ) -> GPBriefSignalTopic? {
        var evidence: [String] = []
        evidence.append("Cardiovascular risk: \(riskProfile.cardioRisk.displayName)")

        if let rhr = lifestyle.averageRestingHeartRate {
            evidence.append("Resting heart rate: \(Int(rhr)) bpm (4-week average)")
        }
        if labSignals.elevatedLipids {
            evidence.append("Lab signals suggest elevated lipids")
        }
        if labSignals.elevatedBloodPressure {
            evidence.append("Lab signals suggest elevated blood pressure")
        }

        guard riskProfile.cardioRisk != .low || lifestyle.averageRestingHeartRate != nil || labSignals.elevatedLipids || labSignals.elevatedBloodPressure else {
            return nil
        }

        return GPBriefSignalTopic(
            signalID: GPConcern.heart.rawValue,
            title: "Heart & circulation",
            severity: riskSeverity(riskProfile.cardioRisk),
            evidenceSummary: evidence.joined(separator: "; ")
        )
    }

    private static func labsTopic(labSignals: LabRiskSignals, labFlags: [LabFlag]) -> GPBriefSignalTopic? {
        guard labSignals.hasAnySignal || !labFlags.isEmpty else { return nil }

        var evidence: [String] = []
        if !labFlags.isEmpty {
            evidence.append("\(labFlags.count) value(s) outside NHS reference range")
            evidence.append(labFlags.prefix(3).map(\.displaySummary).joined(separator: "; "))
        } else {
            evidence.append("Lab risk signals flagged on latest assessment")
        }

        return GPBriefSignalTopic(
            signalID: GPConcern.labs.rawValue,
            title: "Lab results",
            severity: labFlags.isEmpty ? "Worth discussing" : "Review with GP",
            evidenceSummary: evidence.joined(separator: "; ")
        )
    }

    private static func activityTopic(
        riskProfile: AbstractedRiskProfile,
        lifestyle: LifestyleSnapshot
    ) -> GPBriefSignalTopic? {
        guard lifestyle.averageDailySteps > 0 || riskProfile.metabolic != .low else { return nil }

        var evidence: [String] = []
        if lifestyle.averageDailySteps > 0 {
            evidence.append("Daily steps: \(lifestyle.averageDailySteps) (4-week average)")
        }
        evidence.append("Metabolic risk: \(riskProfile.metabolic.displayName)")

        return GPBriefSignalTopic(
            signalID: GPConcern.activity.rawValue,
            title: "Physical activity",
            severity: riskSeverity(riskProfile.metabolic),
            evidenceSummary: evidence.joined(separator: "; ")
        )
    }

    private static func sleepTopic(
        lifestyle: LifestyleSnapshot,
        correlations: [String]
    ) -> GPBriefSignalTopic? {
        var evidence: [String] = []

        if let sleep = lifestyle.averageSleepHours {
            evidence.append("Sleep: \(SleepDurationFormatting.format(hours: sleep)) (4-week average)")
        }

        let sleepCorrelations = correlations.filter {
            $0.lowercased().contains("sleep")
        }
        evidence.append(contentsOf: sleepCorrelations.prefix(2))

        guard !evidence.isEmpty else { return nil }

        return GPBriefSignalTopic(
            signalID: GPConcern.sleep.rawValue,
            title: "Sleep",
            severity: lifestyle.averageSleepHours.map { $0 < 6 ? "Worth discussing" : "Information" } ?? "Information",
            evidenceSummary: evidence.joined(separator: "; ")
        )
    }

    private static func metabolismTopic(
        profile: UserProfile,
        riskProfile: AbstractedRiskProfile,
        labSignals: LabRiskSignals
    ) -> GPBriefSignalTopic? {
        var evidence: [String] = []

        if let bmi = profile.bmi {
            evidence.append("BMI: \(String(format: "%.1f", bmi))")
        }
        evidence.append("Metabolic risk: \(riskProfile.metabolic.displayName)")

        if labSignals.elevatedGlucose, let labs = profile.labResults {
            if let hba1c = labs.hba1c {
                evidence.append("HbA1c: \(String(format: "%.1f", hba1c))%")
            } else if let glucose = labs.bloodSugar {
                evidence.append("Fasting glucose: \(String(format: "%.1f", glucose)) mmol/L")
            }
        }

        guard profile.bmi != nil || riskProfile.metabolic != .low || labSignals.elevatedGlucose else {
            return nil
        }

        return GPBriefSignalTopic(
            signalID: GPConcern.metabolism.rawValue,
            title: "Metabolism & weight",
            severity: riskSeverity(riskProfile.metabolic),
            evidenceSummary: evidence.joined(separator: "; ")
        )
    }

    // MARK: - Screening & questions

    private static func screeningEntries(from profile: UserProfile) -> [ScreeningSnapshot] {
        QuestionnaireKind.activeCases.compactMap { kind in
            guard profile.isComplete(kind) else { return nil }
            let score = profile.score(for: kind)
            return ScreeningSnapshot(
                kind: kind,
                score: score,
                maxScore: kind.maxScore,
                band: kind.band(for: score),
                completedAt: profile.completedAt(kind) ?? profile.createdAt
            )
        }
    }

    private static func suggestedQuestions(
        aiSummary: AISummaryResult?,
        correlations: [String],
        concerns: [String]
    ) -> [String] {
        var questions: [String] = []

        if let actions = aiSummary?.preventiveActions {
            for action in actions.prefix(3) {
                questions.append("Should I \(action.action.lowercased())?")
            }
        }

        if let watchItems = aiSummary?.watchItems {
            for item in watchItems.prefix(2) {
                questions.append("Could you help me understand my \(item.area.lowercased()) results?")
            }
        }

        for correlation in correlations.prefix(2) {
            questions.append("Could \(correlation.lowercased())?")
        }

        if questions.isEmpty {
            questions.append(contentsOf: fallbackQuestions(for: concerns))
        }

        var seen = Set<String>()
        var unique: [String] = []
        for question in questions {
            guard seen.insert(question).inserted else { continue }
            unique.append(question)
            if unique.count == 5 { break }
        }
        return unique
    }

    private static func fallbackQuestions(for concerns: [String]) -> [String] {
        let concernSet = Set(concerns)
        var fallbacks: [String] = []

        if concernSet.isEmpty || concernSet.contains(GPConcern.mood.rawValue) {
            fallbacks.append("Are my mood screening scores something we should follow up on?")
        }
        if concernSet.isEmpty || concernSet.contains(GPConcern.heart.rawValue) {
            fallbacks.append("Should I have any further heart health checks based on my data?")
        }
        if concernSet.isEmpty || concernSet.contains(GPConcern.labs.rawValue) {
            fallbacks.append("Can you explain which of my lab results need attention?")
        }
        if concernSet.isEmpty || concernSet.contains(GPConcern.activity.rawValue) {
            fallbacks.append("What activity level would you recommend for me?")
        }
        if concernSet.isEmpty || concernSet.contains(GPConcern.sleep.rawValue) {
            fallbacks.append("Could my sleep patterns be affecting my health?")
        }

        return fallbacks
    }

    // MARK: - Metadata

    private static func defaultReason(concerns: [String]) -> String {
        guard !concerns.isEmpty else { return "Routine GP visit — sharing recent health data." }
        let labels = concerns.compactMap { GPConcern(rawValue: $0)?.label }
        return "I'd like to discuss: \(labels.joined(separator: ", "))."
    }

    private static func geneticsNote(from profile: UserProfile) -> String? {
        guard let genetics = profile.geneticsProfile, genetics.hasAnyValue else { return nil }
        return "Family history / demo genetics data included for context only."
    }

    private static func dataSourcesNote(
        profile: UserProfile,
        snapshot: WeeklyHealthSnapshot?,
        labFlags: [LabFlag]
    ) -> String {
        var sources: [String] = []

        let completedScreenings = QuestionnaireKind.activeCases.filter { profile.isComplete($0) }
        if !completedScreenings.isEmpty {
            sources.append("\(completedScreenings.count) screening(s) completed")
        }

        if let snapshot, snapshot.averageDailySteps > 0 || snapshot.averageSleepHours != nil {
            let synced = snapshot.fetchedAt.formatted(date: .abbreviated, time: .omitted)
            sources.append("Apple Health synced (\(synced))")
        } else {
            sources.append("Apple Health not synced")
        }

        if profile.labResults?.hasAnyValue == true {
            sources.append("lab results entered")
        }

        if profile.geneticsProfile?.hasAnyValue == true {
            sources.append("family history (demo)")
        }

        if !labFlags.isEmpty {
            sources.append("\(labFlags.count) out-of-range lab value(s)")
        }

        return sources.isEmpty
            ? "Limited data available on device."
            : "Based on \(sources.joined(separator: ", "))."
    }

    private static func disclaimer(generatedAt: Date) -> String {
        let dateString = generatedAt.formatted(date: .long, time: .shortened)
        return """
        \(GPVisitBrief.standardDisclaimer)

        Generated on-device at \(dateString). For discussion with your GP only — not a diagnosis.
        """
    }

    private static func riskSeverity(_ level: RiskLevel) -> String {
        switch level {
        case .low: "Information"
        case .moderate: "Worth watching"
        case .high: "Discuss with GP"
        }
    }

    private static func mentalSeverity(_ flag: MentalFlag) -> String {
        switch flag {
        case .none: "Information"
        case .mild: "Worth watching"
        case .moderateDepression, .moderateAnxiety: "Worth discussing"
        case .severeDepression, .highAnxiety: "Discuss with GP"
        }
    }
}

// MARK: - UserProfile scoring

private extension UserProfile {
    func score(for kind: QuestionnaireKind) -> Int {
        switch kind {
        case .phq9: phq9Score
        case .gad7: gad7Score
        case .who5: who5Score
        case .pss10: pss10Score
        case .sleep: sleepScore
        case .auditC: auditCScore
        case .phq15: phq15Score
        }
    }
}

private extension QuestionnaireKind {
    var maxScore: Int {
        switch self {
        case .phq9: 27
        case .gad7: 21
        case .who5: 25
        case .pss10: 40
        case .sleep: 25
        case .auditC: 12
        case .phq15: 30
        }
    }

    func band(for score: Int) -> String {
        switch self {
        case .phq9:
            switch score {
            case 0...4: "Minimal"
            case 5...9: "Mild"
            case 10...14: "Moderate"
            case 15...19: "Moderately severe"
            default: "Severe"
            }
        case .gad7:
            switch score {
            case 0...4: "Minimal"
            case 5...9: "Mild"
            case 10...14: "Moderate"
            default: "Severe"
            }
        case .who5:
            score <= 12 ? "Low wellbeing" : score <= 18 ? "Moderate" : "Good"
        case .pss10:
            score <= 13 ? "Low stress" : score <= 26 ? "Moderate" : "High stress"
        case .sleep:
            "Recorded"
        case .auditC:
            switch score {
            case 0...3: "Low risk"
            case 4...5: "Increasing risk"
            default: "Higher risk"
            }
        case .phq15:
            score <= 4 ? "Minimal" : score <= 9 ? "Mild" : score <= 14 ? "Moderate" : "Severe"
        }
    }
}

private extension GeneticsProfile {
    var hasAnyValue: Bool {
        quizCompleted || mockUploadCompleted || familyCancer || familyHeart || familyKidney
            || familyNeuro || familyMetabolic || familyBreastOvarian || familyColon || familyDiabetes
    }
}
