import SwiftUI

struct GPVisitBriefView: View {
    let brief: GPVisitBrief

    @State private var showAllLabs = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionCard("Reason for visit", text: brief.reasonForVisit)
                    discussionTopicsSection
                    screeningSection
                    physicalMeasuresSection
                    labsSection
                    questionsSection
                    sectionCard("Data sources", text: brief.dataSourcesNote)
                    if let genetics = brief.geneticsNote {
                        sectionCard("Genetics", text: genetics)
                    }
                    Text(brief.disclaimer)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                        .nhsCard()
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("GP Visit Brief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Share PDF") {
                        GPBriefSharePresenter.sharePDF(from: brief)
                    }
                }
            }
        }
    }

    private var discussionTopicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key discussion topics")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if brief.discussionTopics.isEmpty {
                Text("Complete screenings or add lab data for richer discussion topics.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                ForEach(brief.discussionTopics) { topic in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.title)
                            .font(.subheadline.weight(.semibold))
                        Text(topic.severity)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                        Text(topic.evidenceSummary)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var screeningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screening scores")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if brief.screeningScores.isEmpty {
                Text("No screenings completed yet.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                ForEach(brief.screeningScores) { entry in
                    LabeledContent(entry.kind.title, value: "\(entry.score)/\(entry.maxScore) — \(entry.band)")
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var physicalMeasuresSection: some View {
        let measures = brief.physicalMeasures
        return VStack(alignment: .leading, spacing: 8) {
            Text("Physical measures (4-week averages)")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if measures.averageDailySteps > 0 {
                LabeledContent("Daily steps", value: "\(measures.averageDailySteps)")
            }
            if let rhr = measures.averageRestingHeartRate {
                LabeledContent("Resting heart rate", value: String(format: "%.0f bpm", rhr))
            }
            if let sleep = measures.averageSleepHours {
                LabeledContent("Sleep", value: SleepDurationFormatting.format(hours: sleep))
            }
            if let bmi = measures.bmi {
                LabeledContent("BMI", value: String(format: "%.1f", bmi))
            }

            if measures.averageDailySteps == 0
                && measures.averageRestingHeartRate == nil
                && measures.averageSleepHours == nil
                && measures.bmi == nil {
                Text("No HealthKit averages available.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var labsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Labs")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.primaryBlue)
                Spacer()
                if brief.allLabResults != nil {
                    Button(showAllLabs ? "Show flagged only" : "Show full panel") {
                        showAllLabs.toggle()
                    }
                    .font(.caption)
                }
            }

            if showAllLabs, let labs = brief.allLabResults {
                ForEach(LabBiomarker.coreReferenceBiomarkers, id: \.self) { marker in
                    if let value = LabBiomarkerIO.stringValue(marker, from: labs) {
                        LabeledContent(marker.label, value: "\(value) \(marker.unit)")
                            .font(.caption)
                    }
                }
            } else if brief.abnormalLabs.isEmpty {
                Text("No out-of-range labs recorded.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                ForEach(brief.abnormalLabs) { flag in
                    Text(flag.displaySummary)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested questions for your GP")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if brief.suggestedQuestions.isEmpty {
                Text("Add concerns or complete an assessment for tailored questions.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            } else {
                ForEach(brief.suggestedQuestions, id: \.self) { question in
                    Label(question, systemImage: "questionmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private func sectionCard(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }
}
