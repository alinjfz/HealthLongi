import SwiftUI

struct GPVisitBriefView: View {
    let brief: GPVisitBrief
    let profile: UserProfile

    @State private var showAllLabs = false
    @State private var pdfData: Data?
    @State private var shareURL: URL?
    @State private var showShare = false

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
                        let data = GPBriefPDFRenderer.render(brief)
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("GPVisitBrief.pdf")
                        try? data.write(to: url)
                        pdfData = data
                        shareURL = url
                        showShare = true
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
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
                Text("No active signals — add screenings or lab data for richer topics.")
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

            ForEach(brief.screeningScores) { entry in
                LabeledContent(entry.kind.title, value: "\(entry.score)/\(entry.maxScore) — \(entry.band)")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nhsCard()
    }

    private var physicalMeasuresSection: some View {
        let m = brief.physicalMeasures
        return VStack(alignment: .leading, spacing: 8) {
            Text("Physical measures (4-week averages)")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if m.averageDailySteps > 0 {
                LabeledContent("Daily steps", value: "\(m.averageDailySteps)")
            }
            if let rhr = m.averageRestingHeartRate {
                LabeledContent("Resting heart rate", value: String(format: "%.0f bpm", rhr))
            }
            if let sleep = m.averageSleepHours {
                LabeledContent("Sleep", value: SleepDurationFormatting.format(hours: sleep))
            }
            if let bmi = m.bmi {
                LabeledContent("BMI", value: String(format: "%.1f", bmi))
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

            ForEach(brief.suggestedQuestions, id: \.self) { question in
                Label(question, systemImage: "questionmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
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

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
