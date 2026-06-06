import SwiftUI

struct HealthSummaryInfoSheet: View {
    let assessment: RiskAssessment?
    let userProfile: UserProfile?
    let healthSnapshot: WeeklyHealthSnapshot?
    let summaryResult: AISummaryResult?

    @Environment(\.dismiss) private var dismiss

    private var profile: AbstractedRiskProfile {
        assessment?.abstractedProfile ?? .placeholder
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    dataSourcesSection
                    scoringSection
                    if !profile.correlations.isEmpty {
                        correlationsSection
                    }
                    if profile.labSignals.hasAnySignal {
                        labSignalsSection
                    }
                    generationSection
                    limitationsSection
                    privacySection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("About This Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Health Summary")
                .font(.title3.weight(.semibold))
                .foregroundStyle(NHSTheme.primaryBlue)

            if let assessment {
                Text("Last calculated \(assessment.timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                Text("Complete a check-in to generate your first summary.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

            HStack(spacing: 8) {
                statusChip(
                    label: usedFallback ? "Offline summary" : "AI-generated",
                    icon: usedFallback ? "wifi.slash" : "sparkles",
                    tint: usedFallback ? .orange : NHSTheme.primaryBlue
                )
                statusChip(label: "On-device scoring", icon: "lock.shield.fill", tint: NHSTheme.primaryBlue)
            }
        }
        .nhsCard()
    }

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data Used")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(usedDataSources) { source in
                dataSourceRow(source)
            }

            if !unusedDataSources.isEmpty {
                Text("Available but not used")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NHSTheme.textPrimary)
                    .padding(.top, 6)

                ForEach(unusedDataSources) { source in
                    dataSourceRow(source, muted: true)
                }
            }
        }
        .nhsCard()
    }

    private var scoringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Risk Snapshot")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            riskRow(title: "Cardiovascular", level: profile.cardioRisk.displayName,
                    color: NHSTheme.riskColor(for: profile.cardioRisk),
                    score: assessment?.cardioScore)
            riskRow(title: "Mental health", level: profile.mentalHealth.displayName,
                    color: NHSTheme.mentalColor(for: profile.mentalHealth),
                    score: nil)
            riskRow(title: "Metabolic", level: profile.metabolic.displayName,
                    color: NHSTheme.riskColor(for: profile.metabolic),
                    score: assessment?.metabolicScore)

            Text("Scores are calculated on your device using simplified versions of clinical tools (QRISK3 subset, FINDRISC subset, PHQ-9, and GAD-7). Lab results contribute as anonymised flags — never raw values.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private var correlationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cross-Domain Patterns")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("These patterns were detected from your combined data and may influence your summary and tips.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)

            ForEach(profile.correlations, id: \.self) { key in
                Label(CorrelationLabels.displayName(for: key), systemImage: "link")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .nhsCard()
    }

    private var labSignalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lab Signals Used")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Your saved lab results were converted to high-level flags for scoring. Raw values are never sent to AI.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)

            ForEach(activeLabSignals, id: \.self) { signal in
                Label(signal, systemImage: "flask.fill")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textPrimary)
            }
        }
        .nhsCard()
    }

    private var generationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How the Summary Was Written")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("1. Your device combines questionnaires, Apple Health metrics, demographics, and lab flags into risk levels.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
            Text("2. Only anonymised risk levels and pattern flags are sent to the AI — no raw HealthKit, lab, or genetics data.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
            Text("3. The AI writes a brief, plain-English summary with one practical suggestion.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            if usedFallback {
                Label("AI was unavailable, so a built-in offline summary was used instead.", systemImage: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .nhsCard()
    }

    private var limitationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Limitations")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("This is an early-warning wellness tool, not a clinical diagnosis. Scoring uses simplified subsets of established frameworks. Always consult your GP for medical decisions.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Label("HealthKit data stays on your device", systemImage: "heart.text.square.fill")
            Label("Lab results stay on your device", systemImage: "flask.fill")
            Label("Genetics data is never sent to AI", systemImage: "leaf.fill")
            Label("Only anonymised risk levels may leave your device", systemImage: "lock.shield")
        }
        .font(.subheadline)
        .foregroundStyle(NHSTheme.textSecondary)
        .nhsCard()
    }

    // MARK: - Helpers

    private var usedFallback: Bool {
        summaryResult?.usedFallback ?? assessment?.usedAIFallback ?? false
    }

    private struct DataSourceItem: Identifiable {
        let id: String
        let title: String
        let detail: String
        let icon: String
        let isUsed: Bool
    }

    private var usedDataSources: [DataSourceItem] {
        dataSourceItems.filter(\.isUsed)
    }

    private var unusedDataSources: [DataSourceItem] {
        dataSourceItems.filter { !$0.isUsed }
    }

    private var dataSourceItems: [DataSourceItem] {
        var items: [DataSourceItem] = []

        let phq9Used = (userProfile?.phq9Score ?? 0) > 0
        items.append(DataSourceItem(
            id: "phq9",
            title: "PHQ-9 (mood)",
            detail: phq9Detail,
            icon: "brain.head.profile",
            isUsed: phq9Used
        ))

        let gad7Used = (userProfile?.gad7Score ?? 0) > 0
        items.append(DataSourceItem(
            id: "gad7",
            title: "GAD-7 (anxiety)",
            detail: gad7Detail,
            icon: "waveform.path.ecg",
            isUsed: gad7Used
        ))

        let hkUsed = (healthSnapshot?.averageDailySteps ?? 0) > 0
            || healthSnapshot?.averageRestingHeartRate != nil
            || healthSnapshot?.averageSleepHours != nil
        items.append(DataSourceItem(
            id: "healthkit",
            title: "Apple Health",
            detail: healthKitDetail,
            icon: "heart.text.square.fill",
            isUsed: hkUsed
        ))

        items.append(DataSourceItem(
            id: "demographics",
            title: "Demographics",
            detail: demographicsDetail,
            icon: "person.fill",
            isUsed: userProfile?.onboardingComplete == true
        ))

        let labsUsed = profile.labSignals.hasAnySignal
        items.append(DataSourceItem(
            id: "labs",
            title: "Lab results",
            detail: labsDetail,
            icon: "flask.fill",
            isUsed: labsUsed
        ))

        items.append(DataSourceItem(
            id: "who5",
            title: "WHO-5 (wellbeing)",
            detail: questionnaireDetail(kind: .who5, score: userProfile?.who5Score, complete: userProfile?.who5Complete == true),
            icon: "sun.max.fill",
            isUsed: userProfile?.who5Complete == true
        ))

        items.append(DataSourceItem(
            id: "pss10",
            title: "PSS-10 (stress)",
            detail: questionnaireDetail(kind: .pss10, score: userProfile?.pss10Score, complete: userProfile?.pss10Complete == true),
            icon: "bolt.heart.fill",
            isUsed: userProfile?.pss10Complete == true
        ))

        items.append(DataSourceItem(
            id: "phq15",
            title: "PHQ-15 (physical symptoms)",
            detail: questionnaireDetail(kind: .phq15, score: userProfile?.phq15Score, complete: userProfile?.phq15Complete == true),
            icon: "figure.stand",
            isUsed: userProfile?.phq15Complete == true
        ))

        items.append(DataSourceItem(
            id: "auditC",
            title: "AUDIT-C (alcohol)",
            detail: questionnaireDetail(kind: .auditC, score: userProfile?.auditCScore, complete: userProfile?.auditCComplete == true),
            icon: "wineglass.fill",
            isUsed: userProfile?.auditCComplete == true
        ))

        items.append(DataSourceItem(
            id: "genetics",
            title: "Genetics (beta)",
            detail: userProfile?.geneticsProfile != nil ? "Stored locally — never used in summary" : "Not provided",
            icon: "leaf.fill",
            isUsed: false
        ))

        return items
    }

    private var phq9Detail: String {
        guard let score = userProfile?.phq9Score, score > 0 else { return "Not completed" }
        let date = userProfile?.phq9CompletedAt?.formatted(date: .abbreviated, time: .omitted) ?? "recently"
        return "Score \(score) — completed \(date)"
    }

    private var gad7Detail: String {
        guard let score = userProfile?.gad7Score, score > 0 else { return "Not completed" }
        let date = userProfile?.gad7CompletedAt?.formatted(date: .abbreviated, time: .omitted) ?? "recently"
        return "Score \(score) — completed \(date)"
    }

    private var healthKitDetail: String {
        guard let snapshot = healthSnapshot else { return "Not connected" }
        var parts: [String] = []
        if snapshot.averageDailySteps > 0 {
            parts.append("\(snapshot.averageDailySteps.formatted()) steps/day")
        }
        if let hr = snapshot.averageRestingHeartRate {
            parts.append("\(Int(hr)) bpm resting HR")
        }
        if let sleep = snapshot.averageSleepHours {
            parts.append(String(format: "%.1f h sleep", sleep))
        }
        if let mins = snapshot.weeklyExerciseMinutes {
            parts.append("\(mins) min exercise/week")
        }
        let timing = snapshot.fetchedAt.formatted(.relative(presentation: .named))
        return parts.isEmpty ? "No readable metrics yet" : "\(parts.joined(separator: " · ")) — synced \(timing)"
    }

    private var demographicsDetail: String {
        guard let userProfile, userProfile.onboardingComplete else { return "Not completed" }
        return "Age \(userProfile.age), \(userProfile.sex.displayName), \(userProfile.smokingStatus.displayName)"
    }

    private var labsDetail: String {
        guard let labs = userProfile?.labResults, labs.hasAnyValue else { return "Not entered" }
        let timing = labs.lastUpdated.formatted(.relative(presentation: .named))
        return profile.labSignals.hasAnySignal
            ? "Active flags from labs saved \(timing)"
            : "Saved \(timing) — values within normal ranges for scoring"
    }

    private func questionnaireDetail(kind: QuestionnaireKind, score: Int?, complete: Bool) -> String {
        guard complete, let score else { return "Not completed" }
        let date = userProfile?.completedAt(kind)?.formatted(date: .abbreviated, time: .omitted) ?? "recently"
        return "Score \(score) — completed \(date)"
    }

    private var activeLabSignals: [String] {
        var signals: [String] = []
        if profile.labSignals.elevatedLipids { signals.append("Elevated lipids") }
        if profile.labSignals.elevatedGlucose { signals.append("Elevated glucose / HbA1c") }
        if profile.labSignals.elevatedBloodPressure { signals.append("Elevated blood pressure") }
        if profile.labSignals.elevatedInflammation { signals.append("Elevated inflammation markers") }
        if profile.labSignals.elevatedWaist { signals.append("Elevated waist circumference") }
        if profile.labSignals.kidneyConcern { signals.append("Reduced kidney function") }
        if profile.labSignals.thyroidConcern { signals.append("Thyroid markers outside range") }
        if profile.labSignals.lowVitamins { signals.append("Low vitamin markers") }
        return signals
    }

    private func dataSourceRow(_ source: DataSourceItem, muted: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: source.icon)
                .font(.subheadline)
                .foregroundStyle(muted ? NHSTheme.textSecondary : NHSTheme.primaryBlue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(muted ? NHSTheme.textSecondary : NHSTheme.textPrimary)
                Text(source.detail)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
    }

    private func riskRow(title: String, level: String, color: Color, score: Int?) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            if let score {
                Text("Score \(score)")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
            Text(level)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
    }

    private func statusChip(label: String, icon: String, tint: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}
