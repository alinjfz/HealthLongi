import SwiftUI
import SwiftData

struct GeneticsBetaFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var step: GeneticsStep = .quiz
    @State private var draft = GeneticsProfile.empty

    enum GeneticsStep {
        case quiz, report, browse
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .quiz:
                    FamilyHistoryQuizView(draft: $draft) {
                        draft.quizCompleted = true
                        draft.quizCompletedAt = .now
                        profile.geneticsProfile = draft
                        try? modelContext.save()
                        step = .report
                    }
                case .report:
                    MockGeneticsReportView(profile: draft) {
                        draft.reportViewed = true
                        profile.geneticsProfile = draft
                        try? modelContext.save()
                        step = .browse
                    }
                case .browse:
                    GeneticsBrowseView()
                }
            }
            .navigationTitle("Longevity Genetics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if let existing = profile.geneticsProfile {
                    draft = existing
                }
                applyMockDemoIfNeeded()
                step = initialStep(for: draft)
            }
        }
    }

    private func initialStep(for profile: GeneticsProfile) -> GeneticsStep {
        if profile.quizCompleted {
            return profile.reportViewed ? .browse : .report
        }
        return .quiz
    }

    private func applyMockDemoIfNeeded() {
        guard !draft.mockUploadCompleted else { return }
        draft.mockUploadCompleted = true
        draft.uploadedAt = .now
        draft.mockVariantIDs = MockDNAReport.defaultUploadSelection()
        profile.geneticsProfile = draft
        try? modelContext.save()
    }
}

struct FamilyHistoryQuizView: View {
    @Binding var draft: GeneticsProfile
    var onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Family History")
                    .font(.title2.bold())
                    .foregroundStyle(NHSTheme.primaryBlue)

                Text("Answer a few questions about close relatives (parents, siblings, grandparents). A demo DNA preview is included — this is not a genetic test.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)

                Label("Demo preview — not a genetic test", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                toggleRow("Any family history of cancer?", $draft.familyCancer)
                toggleRow("Breast or ovarian cancer in the family?", $draft.familyBreastOvarian)
                toggleRow("Colon or bowel cancer in the family?", $draft.familyColon)
                toggleRow("Early heart disease or stroke in the family?", $draft.familyHeart)
                toggleRow("Kidney disease in the family?", $draft.familyKidney)
                toggleRow("Alzheimer's or Parkinson's in the family?", $draft.familyNeuro)
                toggleRow("Inherited metabolic conditions?", $draft.familyMetabolic)
                toggleRow("Type 2 diabetes in the family?", $draft.familyDiabetes)

                Button("See demo report") { onComplete() }
                    .buttonStyle(NHSPrimaryButtonStyle())
            }
            .padding()
        }
        .background(NHSTheme.background)
    }

    private func toggleRow(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textPrimary)
        }
        .nhsCard()
    }
}

struct MockGeneticsReportView: View {
    let profile: GeneticsProfile
    var onBrowse: () -> Void

    private var uploadVariants: [MockDNAVariant] {
        MockDNAReport.variants(for: profile.mockVariantIDs)
    }

    private var highlights: [GeneticsCondition] {
        MockDNAReport.highlightedConditions(for: profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Demo preview — not a genetic test", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("Your Longevity Preview")
                    .font(.title2.bold())
                    .foregroundStyle(NHSTheme.primaryBlue)

                Text("Based on your family history and demo DNA data, these hereditary panels might be worth discussing with a GP in a real clinical setting.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)

                DNAHelixVisualizationView(variants: uploadVariants)
                DNAVariantChartView(variants: uploadVariants)
                GeneConditionMapView(variants: uploadVariants)

                Text("Highlighted conditions")
                    .font(.headline)
                    .foregroundStyle(NHSTheme.primaryBlue)

                ForEach(highlights) { condition in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(condition.condition)
                            .font(.headline)
                        Text("Genes: \(condition.genes.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                        Text(condition.summary)
                            .font(.subheadline)
                            .foregroundStyle(NHSTheme.textPrimary)
                    }
                    .nhsCard()
                }

                Button("Browse all conditions") { onBrowse() }
                    .buttonStyle(NHSPrimaryButtonStyle())
            }
            .padding()
        }
        .background(NHSTheme.background)
    }
}

struct GeneticsBrowseView: View {
    @State private var search = ""

    private var filtered: [GeneticsCondition] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return GeneticsCatalog.conditions }
        return GeneticsCatalog.conditions.filter {
            $0.condition.lowercased().contains(query) || $0.genes.joined().lowercased().contains(query)
        }
    }

    var body: some View {
        List {
            ForEach(GeneticsCategory.allCases) { category in
                let items = filtered.filter { $0.category == category }
                if !items.isEmpty {
                    Section(category.title) {
                        ForEach(items) { condition in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(condition.condition)
                                    .font(.headline)
                                Text(condition.genes.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(NHSTheme.textSecondary)
                                Text(condition.summary)
                                    .font(.caption)
                                    .foregroundStyle(NHSTheme.textPrimary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Search conditions or genes")
    }
}

struct GeneticsBetaCard: View {
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(NHSTheme.primaryBlue)
                    .frame(width: 44, height: 44)
                    .background(NHSTheme.primaryBlue.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Longevity Genetics")
                            .font(.headline)
                            .foregroundStyle(NHSTheme.textPrimary)
                        Text("Beta")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(NHSTheme.primaryBlue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    Text("Family history & demo DNA insights")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NHSTheme.textSecondary)
            }
            .nhsCard()
        }
        .buttonStyle(.plain)
    }
}
