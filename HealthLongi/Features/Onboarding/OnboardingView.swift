import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var age = 30
    @State private var sex: Sex = .female
    @State private var smokingStatus: SmokingStatus = .never

    var onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.headline)
                            .foregroundStyle(NHSTheme.textPrimary)
                        Stepper("\(age) years", value: $age, in: 18...100)
                    }
                    .nhsCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sex")
                            .font(.headline)
                            .foregroundStyle(NHSTheme.textPrimary)
                        Picker("Sex", selection: $sex) {
                            ForEach(Sex.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .nhsCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smoking status")
                            .font(.headline)
                            .foregroundStyle(NHSTheme.textPrimary)
                        Picker("Smoking", selection: $smokingStatus) {
                            ForEach(SmokingStatus.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .nhsCard()

                    Button("Continue") {
                        saveProfile()
                    }
                    .buttonStyle(NHSPrimaryButtonStyle())
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Welcome")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vitals & Mind")
                .font(.largeTitle.bold())
                .foregroundStyle(NHSTheme.primaryBlue)
            Text("A privacy-first health companion. Your data stays on your device.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
    }

    private func saveProfile() {
        if let existing = profiles.first {
            existing.age = age
            existing.sex = sex
            existing.smokingStatus = smokingStatus
            existing.onboardingComplete = true
        } else {
            let profile = UserProfile(
                age: age,
                sex: sex,
                smokingStatus: smokingStatus,
                onboardingComplete: true
            )
            modelContext.insert(profile)
        }
        try? modelContext.save()
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}
