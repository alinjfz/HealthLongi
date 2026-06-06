import SwiftUI

struct DataSourceInfoSheet: View {
    let domain: HealthDomain

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    dataSourcesSection
                    calculationSection
                    limitationsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Data Sources & Methodology")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(domain.title, systemImage: domain.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(NHSTheme.primaryBlue)

            Text(domain.subtitle)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    // MARK: - Data Sources

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Data Sources")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(dataSources, id: \.title) { source in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: source.icon)
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.primaryBlue)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(NHSTheme.textPrimary)
                        Text(source.detail)
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                }
            }
        }
        .nhsCard()
    }

    // MARK: - Calculation Methodology

    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How It's Calculated")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text(methodologyOverview)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(scoringFactors, id: \.factor) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(NHSTheme.primaryBlue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.factor)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(NHSTheme.textPrimary)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                    }
                }
            }

            if let thresholds = riskThresholds {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Risk Thresholds")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NHSTheme.textPrimary)

                    ForEach(thresholds, id: \.label) { threshold in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(threshold.color)
                                .frame(width: 10, height: 10)
                            Text(threshold.label)
                                .font(.caption)
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .nhsCard()
    }

    // MARK: - Limitations

    private var limitationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Limitations")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Text(limitationsText)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    // MARK: - Domain-Specific Data

    private struct DataSourceItem {
        let title: String
        let detail: String
        let icon: String
    }

    private struct ScoringFactor {
        let factor: String
        let detail: String
    }

    private struct RiskThreshold {
        let label: String
        let color: Color
    }

    private var dataSources: [DataSourceItem] {
        switch domain {
        case .cardiovascular:
            [
                DataSourceItem(title: "Apple Health (HealthKit)", detail: "Resting heart rate, weekly step count, physical activity minutes", icon: "heart.text.square"),
                DataSourceItem(title: "User Profile", detail: "Age, sex, and smoking status collected during onboarding", icon: "person.fill"),
            ]
        case .mental:
            [
                DataSourceItem(title: "PHQ-9 Questionnaire", detail: "9-item Patient Health Questionnaire for depression screening (scored 0–27)", icon: "list.clipboard"),
                DataSourceItem(title: "GAD-7 Questionnaire", detail: "7-item Generalized Anxiety Disorder assessment (scored 0–21)", icon: "list.clipboard"),
            ]
        case .metabolic:
            [
                DataSourceItem(title: "Apple Health (HealthKit)", detail: "Weekly step count and physical activity minutes", icon: "heart.text.square"),
                DataSourceItem(title: "User Profile", detail: "Age and BMI (body mass index) collected during onboarding", icon: "person.fill"),
            ]
        }
    }

    private var methodologyOverview: String {
        switch domain {
        case .cardiovascular:
            "Your cardiovascular risk is estimated using a simplified approximation of the QRISK3 framework. Points are assigned based on established clinical risk factors, and the total score maps to a risk level."
        case .mental:
            "Your mental health status is determined by combining scores from two clinically validated screening tools — the PHQ-9 for depression and the GAD-7 for anxiety. Each has well-established thresholds used in NHS practice."
        case .metabolic:
            "Your metabolic risk is estimated using a subset of the FINDRISC (Finnish Diabetes Risk Score), a validated tool for assessing 10-year type 2 diabetes risk. We use a simplified version adapted for self-reported and HealthKit data."
        }
    }

    private var scoringFactors: [ScoringFactor] {
        switch domain {
        case .cardiovascular:
            [
                ScoringFactor(factor: "Age", detail: "+2 (40–49), +4 (50–59), +6 (60+)"),
                ScoringFactor(factor: "Smoking", detail: "+5 (current/vaping), +2 (former)"),
                ScoringFactor(factor: "Resting Heart Rate", detail: "+3 (>80 bpm), +1 (>70 bpm)"),
                ScoringFactor(factor: "Physical Activity", detail: "+2 if under 30 min/day"),
                ScoringFactor(factor: "Sex", detail: "+1 for males aged 45+"),
            ]
        case .mental:
            [
                ScoringFactor(factor: "GAD-7 Score", detail: "≥15 → High anxiety; ≥10 → Moderate anxiety; ≥5 → Mild"),
                ScoringFactor(factor: "PHQ-9 Score", detail: "≥20 → Severe depression; ≥10 → Moderate depression; ≥5 → Mild"),
                ScoringFactor(factor: "Priority", detail: "Anxiety flags take precedence over depression flags at equal severity"),
            ]
        case .metabolic:
            [
                ScoringFactor(factor: "Age", detail: "+2 (45–54), +3 (55–64), +4 (65+)"),
                ScoringFactor(factor: "BMI", detail: "+1 (25–29), +3 (30–34), +4 (35+)"),
                ScoringFactor(factor: "Physical Activity", detail: "+2 if under 30 min/day"),
                ScoringFactor(factor: "Weekly Steps", detail: "+1 if under 5,000 steps/day"),
            ]
        }
    }

    private var riskThresholds: [RiskThreshold]? {
        switch domain {
        case .cardiovascular:
            [
                RiskThreshold(label: "Low: score 0–7", color: .green),
                RiskThreshold(label: "Moderate: score 8–13", color: .orange),
                RiskThreshold(label: "High: score 14+", color: .red),
            ]
        case .metabolic:
            [
                RiskThreshold(label: "Low: score 0–6", color: .green),
                RiskThreshold(label: "Moderate: score 7–10", color: .orange),
                RiskThreshold(label: "High: score 11+", color: .red),
            ]
        case .mental:
            nil // Mental health uses categorical flags, not score thresholds
        }
    }

    private var limitationsText: String {
        switch domain {
        case .cardiovascular:
            "This is a simplified approximation of QRISK3 and does not include all clinical factors (e.g., blood pressure, cholesterol, family history, ethnicity, or existing conditions). It is not a clinical diagnosis — always consult your GP for a comprehensive cardiovascular assessment."
        case .mental:
            "PHQ-9 and GAD-7 are screening tools, not diagnostic instruments. They provide an indication of symptom severity but cannot replace a clinical evaluation by a qualified mental health professional."
        case .metabolic:
            "This is a subset of the full FINDRISC tool and omits some factors (e.g., diet, family history, waist circumference, history of high blood glucose). It provides a general indication and is not a substitute for clinical metabolic assessment."
        }
    }
}

#Preview {
    DataSourceInfoSheet(domain: .cardiovascular)
}
