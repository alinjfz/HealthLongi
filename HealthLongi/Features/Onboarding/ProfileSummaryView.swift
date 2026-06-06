import SwiftUI
import SwiftData

struct ProfileSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \RiskAssessment.timestamp, order: .reverse) private var assessments: [RiskAssessment]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = profiles.first {
                        profileCard(profile)
                    }

                    historySection

                    #if DEBUG
                    Button("Load Demo Data") {
                        DemoSeeder.seedDemoProfile(context: modelContext)
                    }
                    .buttonStyle(.bordered)
                    .tint(NHSTheme.primaryBlue)
                    #endif
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Profile")
        }
    }

    private func profileCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demographics")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            LabeledContent("Age", value: "\(profile.age)")
            LabeledContent("Sex", value: profile.sex.displayName)
            LabeledContent("Smoking", value: profile.smokingStatus.displayName)
            Divider()
            LabeledContent("PHQ-9", value: "\(profile.phq9Score)")
            LabeledContent("GAD-7", value: "\(profile.gad7Score)")
            if let bmi = profile.bmi {
                LabeledContent("BMI", value: String(format: "%.1f", bmi))
            }
            if let activity = profile.physicalActivityMinutes {
                LabeledContent("Activity", value: "\(activity) min/week")
            }
        }
        .nhsCard()
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assessment History")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            if assessments.isEmpty {
                Text("No assessments yet. Complete questionnaires and run an assessment from Dashboard.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
                    .nhsCard()
            } else {
                ForEach(assessments) { assessment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assessment.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.medium))
                        Text("Cardio: \(assessment.abstractedProfile.cardioRisk.displayName) · Mental: \(assessment.abstractedProfile.mentalHealth.displayName)")
                            .font(.caption)
                            .foregroundStyle(NHSTheme.textSecondary)
                    }
                    .nhsCard()
                }
            }
        }
    }
}

#Preview {
    ProfileSummaryView()
        .modelContainer(for: [UserProfile.self, RiskAssessment.self], inMemory: true)
}
