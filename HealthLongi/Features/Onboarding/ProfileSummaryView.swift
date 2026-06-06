import SwiftUI
import SwiftData

struct ProfileSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showEditDemographics = false
    @State private var showAbout = false
    @State private var showGDPRDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = profiles.first {
                        profileCard(profile)

                        Button("Edit Demographics") {
                            showEditDemographics = true
                        }
                        .buttonStyle(.bordered)
                        .tint(NHSTheme.primaryBlue)

                        settingsSection
                    }

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
            .sheet(isPresented: $showEditDemographics) {
                if let profile = profiles.first {
                    EditDemographicsView(profile: profile)
                }
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showGDPRDelete) {
                GDPRDeleteView()
            }
        }
    }

    private func profileCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demographics")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            LabeledContent("Date of Birth", value: profile.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("Age", value: "\(profile.age)")
            LabeledContent("Sex at birth", value: profile.sex.displayName)
            if let identity = profile.genderIdentity, !identity.isEmpty {
                LabeledContent("Gender identity", value: identity)
            }
            LabeledContent("Smoking", value: profile.smokingStatus.displayName)
            if let frequency = profile.smokingFrequency, !frequency.isEmpty {
                LabeledContent("Frequency", value: frequency)
            }
            Divider()
            LabeledContent("PHQ-9", value: "\(profile.phq9Score)")
            LabeledContent("GAD-7", value: "\(profile.gad7Score)")
            if let bmi = profile.bmi {
                LabeledContent("BMI", value: String(format: "%.1f", bmi))
            }
            if let activity = profile.physicalActivityMinutes {
                LabeledContent("Activity", value: "\(activity) min/week")
            }
            if profile.labResults != nil {
                LabeledContent("Lab data", value: "Saved")
            }
        }
        .nhsCard()
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(NHSTheme.primaryBlue)

            Button("About Us") {
                showAbout = true
            }
            .buttonStyle(.bordered)
            .tint(NHSTheme.primaryBlue)

            Button("Delete My Data") {
                showGDPRDelete = true
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .foregroundStyle(.red)
        }
    }
}

#Preview {
    ProfileSummaryView()
        .modelContainer(for: [UserProfile.self, RiskAssessment.self], inMemory: true)
}
