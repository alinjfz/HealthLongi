import SwiftUI
import SwiftData
import HealthKit

struct OnboardingView: View {
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    @State private var sex: Sex = .female
    @State private var smokingStatus: SmokingStatus = .never
    @State private var smokingFrequency = ""
    @State private var showGenderIdentity = false
    @State private var genderIdentity = ""
    @State private var errorMessage: String?
    @State private var healthKitPrefilled = false

    var onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    dateOfBirthSection
                    sexSection
                    smokingSection

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
            .onAppear {
                prefetchFromHealthKit()
            }
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

            if healthKitPrefilled {
                Label("Some details pre-filled from Apple Health", systemImage: "heart.text.square.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.top, 2)
            }
        }
    }

    private var dateOfBirthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            Text("Age: \(ageFromDOB)")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private var sexSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sex at birth")
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)

            HStack(spacing: 12) {
                ForEach(Sex.allCases) { option in
                    Button {
                        sex = option
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: sex == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(sex == option ? NHSTheme.primaryBlue : NHSTheme.textSecondary)
                            Text(option.displayName)
                                .foregroundStyle(NHSTheme.textPrimary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(sex == option ? NHSTheme.lightBlue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(sex == option ? NHSTheme.primaryBlue : NHSTheme.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Toggle("I identify differently from sex at birth", isOn: $showGenderIdentity)

            if showGenderIdentity {
                GenderIdentityView(genderIdentity: $genderIdentity)
            }
        }
        .nhsCard()
    }

    private var smokingSection: some View {
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
    }

    private var ageFromDOB: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
    }

    private func prefetchFromHealthKit() {
        let hkManager = dependencies.healthDataProvider
        guard let manager = hkManager as? HealthKitManager else { return }

        if let dob = manager.fetchDateOfBirth() {
            dateOfBirth = dob
            healthKitPrefilled = true
        }

        if let biologicalSex = manager.fetchBiologicalSex() {
            switch biologicalSex {
            case .female: sex = .female; healthKitPrefilled = true
            case .male: sex = .male; healthKitPrefilled = true
            default: break
            }
        }
    }

    private func saveProfile() {
        let age = ageFromDOB
        guard (18...100).contains(age) else {
            errorMessage = "You must be between 18 and 100 years old."
            return
        }

        errorMessage = nil

        if let existing = profiles.first {
            existing.dateOfBirth = dateOfBirth
            existing.sex = sex
            existing.smokingStatus = smokingStatus
            existing.smokingFrequency = smokingStatus.hasFrequency ? smokingFrequency.nilIfEmpty : nil
            existing.genderIdentity = showGenderIdentity ? genderIdentity.nilIfEmpty : nil
            existing.onboardingComplete = true
        } else {
            let profile = UserProfile(
                dateOfBirth: dateOfBirth,
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
        .environment(\.appDependencies, .preview())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
