import SwiftUI
import SwiftData

struct BodyMapView: View {
    let profile: AbstractedRiskProfile
    let snapshot: WeeklyHealthSnapshot
    let labResults: LabResults?
    let userProfile: UserProfile?

    @Environment(\.modelContext) private var modelContext
    @State private var activeSheet: BodyMapSheet?

    private var regionColors: [BodyRegion: Color] {
        Dictionary(uniqueKeysWithValues: BodyRegion.allCases.map { region in
            (region, BodyRegionMapping.color(for: region, profile: profile, snapshot: snapshot, labResults: labResults))
        })
    }

    var body: some View {
        AnatomyBodyMapIllustrationView(
            regionColors: regionColors,
            selectedRegion: activeSheet?.selectedRegion
        ) { region in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                activeSheet = .region(region)
            }
        }
        .safeAreaPadding(.top, 12)
        .aspectRatio(300 / 520, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .region(let region):
                BodyRegionExplanationSheet(
                    region: region,
                    color: regionColor(region),
                    profile: profile,
                    snapshot: snapshot,
                    labResults: labResults,
                    userProfile: userProfile,
                    onOpenQuestionnaire: { kind in
                        activeSheet = .questionnaire(kind)
                    }
                )
                .presentationDetents([.medium, .large])
            case .questionnaire(let kind):
                QuestionnaireSheetView(kind: kind, profile: userProfile, modelContext: modelContext) {}
            }
        }
    }

    private func regionColor(_ region: BodyRegion) -> Color {
        regionColors[region] ?? .gray
    }
}

private enum BodyMapSheet: Identifiable {
    case region(BodyRegion)
    case questionnaire(QuestionnaireKind)

    var id: String {
        switch self {
        case .region(let region): "region-\(region.rawValue)"
        case .questionnaire(let kind): "questionnaire-\(kind.rawValue)"
        }
    }

    var selectedRegion: BodyRegion? {
        if case .region(let region) = self { return region }
        return nil
    }
}

private struct BodyRegionExplanationSheet: View {
    let region: BodyRegion
    let color: Color
    let profile: AbstractedRiskProfile
    let snapshot: WeeklyHealthSnapshot
    let labResults: LabResults?
    let userProfile: UserProfile?
    let onOpenQuestionnaire: (QuestionnaireKind) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.18))
                    .overlay(
                        Image(systemName: region.symbolName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(color)
                    )
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(region.displayName)
                        .font(.title3.weight(.bold))
                    Text(region.categoryTitle)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Spacer()

                Text(statusLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.13), in: Capsule())
            }

            Text("Why this area is \(statusLabel.lowercased())")
                .font(.headline)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(reasonLines, id: \.self) { reason in
                    Label(reason, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textPrimary)
                        .labelStyle(.titleAndIcon)
                }
            }

            if labLines.isEmpty {
                Label("No lab results are available for this body area yet, so this colour is based on questionnaire and HealthKit data only.", systemImage: "testtube.2")
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Lab results considered", systemImage: "testtube.2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NHSTheme.textSecondary)
                    ForEach(labLines, id: \.self) { lab in
                        Text(lab)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
                .padding(.top, 4)
            }

            assessmentCTASection
        }
        .padding()
        }
    }

    @ViewBuilder
    private var assessmentCTASection: some View {
        if !region.relatedQuestionnaires.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Related assessments")
                    .font(.headline)
                    .padding(.top, 12)

                Text(region.assessmentPrompt)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)

                ForEach(region.relatedQuestionnaires) { kind in
                    Button {
                        onOpenQuestionnaire(kind)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: kind.icon)
                                .font(.title3)
                                .foregroundStyle(NHSTheme.primaryBlue)
                                .frame(width: 40, height: 40)
                                .background(NHSTheme.lightBlue)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(NHSTheme.textPrimary)
                                Text(kind.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(NHSTheme.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()

                            if userProfile?.isComplete(kind) == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Start")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(NHSTheme.primaryBlue)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                        .padding(12)
                        .background(NHSTheme.lightBlue.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusLabel: String {
        switch region {
        case .brain, .leftShoulder, .rightHip, .leftKnee:
            return profile.mentalHealth.displayName
        case .heart:
            return profile.cardioRisk.displayName
        case .lungs:
            if let oxygen = snapshot.oxygenSaturation {
                if oxygen >= 95 { return "Good" }
                if oxygen >= 90 { return "Watch" }
                return "Low oxygen"
            }
            return profile.cardioRisk.displayName
        case .abdomen:
            return profile.metabolic.displayName
        }
    }

    private var reasonLines: [String] {
        switch region {
        case .brain:
            return [
                "Mental-health status is based on your PHQ-9 and GAD-7 questionnaire results.",
                sleepReason,
                mindfulnessReason
            ].compactMap(\.self)
        case .heart:
            return [
                "Cardiovascular colour comes from your heart and circulation risk profile.",
                heartRateReason,
                stepsReason
            ].compactMap(\.self)
        case .lungs:
            return [
                oxygenReason,
                "If oxygen data is missing, lung colour falls back to cardiovascular risk."
            ].compactMap(\.self)
        case .abdomen:
            return [
                "Abdomen colour reflects metabolic risk, including weight, activity, and diabetes-related inputs.",
                bmiReason,
                stepsReason
            ].compactMap(\.self)
        case .leftShoulder, .rightHip, .leftKnee:
            return [
                "Joint/body-symptom areas use the physical-symptom screening pathway.",
                "Inflammation, muscle, and vitamin D labs can raise this area when available."
            ]
        }
    }

    private var labLines: [String] {
        guard let labs = labResults, labs.hasAnyValue else { return [] }

        switch region {
        case .brain:
            return [
                lab("TSH", labs.tsh),
                lab("FT4", labs.ft4),
                lab("Vitamin B12", labs.vitaminB12),
                lab("Folate", labs.folate),
                lab("Vitamin D", labs.vitaminD),
                lab("Cortisol", labs.cortisol)
            ].compactMap(\.self)
        case .heart:
            return [
                lab("LDL cholesterol", labs.ldlCholesterol),
                lab("Total cholesterol", labs.cholesterol),
                lab("Triglycerides", labs.triglycerides),
                lab("ApoB", labs.apoB),
                bloodPressureLab,
                lab("CRP", labs.crp)
            ].compactMap(\.self)
        case .lungs:
            return [
                lab("CRP", labs.crp),
                lab("ESR", labs.esr)
            ].compactMap(\.self)
        case .abdomen:
            return [
                lab("HbA1c", labs.hba1c),
                lab("Blood sugar", labs.bloodSugar),
                lab("Triglycerides", labs.triglycerides),
                lab("Waist circumference", labs.waistCircumference),
                lab("ALT", labs.alt),
                lab("AST", labs.ast),
                lab("eGFR", labs.egfr)
            ].compactMap(\.self)
        case .leftShoulder, .rightHip, .leftKnee:
            return [
                lab("CRP", labs.crp),
                lab("ESR", labs.esr),
                lab("CK", labs.ck),
                lab("Vitamin D", labs.vitaminD)
            ].compactMap(\.self)
        }
    }

    private var sleepReason: String? {
        guard let hours = snapshot.averageSleepHours else { return nil }
        return String(format: "Average sleep is %.1f hours per night.", hours)
    }

    private var mindfulnessReason: String? {
        guard let minutes = snapshot.mindfulMinutes else { return nil }
        return String(format: "Mindfulness average is %.0f minutes per day.", minutes)
    }

    private var heartRateReason: String? {
        guard let heartRate = snapshot.averageRestingHeartRate else { return nil }
        return "Resting heart rate average is \(Int(heartRate.rounded())) bpm."
    }

    private var stepsReason: String? {
        guard snapshot.hasStepData else { return nil }
        return "Average daily steps are \(snapshot.averageDailySteps.formatted())."
    }

    private var oxygenReason: String? {
        guard let oxygen = snapshot.oxygenSaturation else { return "No oxygen saturation data is available yet." }
        return "Oxygen saturation average is \(Int(oxygen.rounded()))%."
    }

    private var bmiReason: String? {
        guard let bmi = snapshot.bmi else { return nil }
        return String(format: "BMI from available body metrics is %.1f.", bmi)
    }

    private var bloodPressureLab: String? {
        guard let labs = labResults,
              labs.bloodPressureSystolic != nil || labs.bloodPressureDiastolic != nil
        else { return nil }

        return "Blood pressure: \(labs.bloodPressureSystolic.map(String.init) ?? "-")/\(labs.bloodPressureDiastolic.map(String.init) ?? "-")"
    }

    private func lab(_ label: String, _ value: Double?) -> String? {
        guard let value else { return nil }
        return "\(label): \(value.formatted(.number.precision(.fractionLength(0...1))))"
    }
}

private extension BodyRegion {
    var symbolName: String {
        switch self {
        case .brain: "brain.head.profile"
        case .heart: "heart.fill"
        case .lungs: "lungs.fill"
        case .abdomen: "figure.core.training"
        case .leftShoulder: "figure.strengthtraining.traditional"
        case .rightHip: "figure.walk"
        case .leftKnee: "figure.run"
        }
    }

    var categoryTitle: String {
        switch self {
        case .brain: "Mental Health"
        case .heart: "Cardiovascular"
        case .lungs: "Respiratory"
        case .abdomen: "Metabolic"
        case .leftShoulder, .rightHip, .leftKnee: "Body Symptoms"
        }
    }
}
