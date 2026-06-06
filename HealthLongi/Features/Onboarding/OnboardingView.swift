import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var ageText = "30"
    @State private var sex: Sex = .female
    @State private var smokingStatus: SmokingStatus = .never
    @State private var smokingFrequency = ""
    @State private var showGenderIdentity = false
    @State private var genderIdentity = ""
    @State private var errorMessage: String?

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
                        HStack {
                            TextField("Enter your age", text: $ageText)
                                .keyboardType(.numberPad)
                            Text("years")
                                .foregroundStyle(NHSTheme.textSecondary)
                        }
                    }
                    .nhsCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sex at birth")
                            .font(.headline)
                            .foregroundStyle(NHSTheme.textPrimary)
                        Picker("Sex at birth", selection: $sex) {
                            ForEach(Sex.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)

                        Toggle("I identify differently from sex at birth", isOn: $showGenderIdentity)

                        if showGenderIdentity {
                            GenderIdentityView(genderIdentity: $genderIdentity)
                        }
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

                        if smokingStatus.hasFrequency {
                            TextField("How often? (e.g. weekly)", text: $smokingFrequency)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .nhsCard()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

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
        guard let age = Int(ageText.trimmingCharacters(in: .whitespaces)),
              (18...100).contains(age) else {
            errorMessage = "Please enter a valid age between 18 and 100."
            return
        }

        errorMessage = nil

        if let existing = profiles.first {
            existing.age = age
            existing.sex = sex
            existing.smokingStatus = smokingStatus
            existing.smokingFrequency = smokingStatus.hasFrequency ? smokingFrequency.nilIfEmpty : nil
            existing.genderIdentity = showGenderIdentity ? genderIdentity.nilIfEmpty : nil
            existing.onboardingComplete = true
        } else {
            let profile = UserProfile(
                age: age,
                sex: sex,
                smokingStatus: smokingStatus,
                smokingFrequency: smokingStatus.hasFrequency ? smokingFrequency.nilIfEmpty : nil,
                genderIdentity: showGenderIdentity ? genderIdentity.nilIfEmpty : nil,
                onboardingComplete: true
            )
            modelContext.insert(profile)
        }
        try? modelContext.save()
        onComplete()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}
