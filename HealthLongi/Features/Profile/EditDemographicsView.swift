import SwiftUI
import SwiftData

struct EditDemographicsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var ageText = ""
    @State private var sex: Sex = .female
    @State private var smokingStatus: SmokingStatus = .never
    @State private var smokingFrequency = ""
    @State private var showGenderIdentity = false
    @State private var genderIdentity = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ageSection
                    sexSection
                    smokingSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Save Changes") { save() }
                        .buttonStyle(NHSPrimaryButtonStyle())
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Edit Demographics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadValues() }
        }
    }

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age")
                .font(.headline)
            HStack {
                TextField("Enter your age", text: $ageText)
                    .keyboardType(.numberPad)
                Text("years")
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
    }

    private var sexSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sex at birth")
                .font(.headline)
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
    }

    private var smokingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Smoking status")
                .font(.headline)
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

    private func loadValues() {
        ageText = "\(profile.age)"
        sex = profile.sex
        smokingStatus = profile.smokingStatus
        smokingFrequency = profile.smokingFrequency ?? ""
        genderIdentity = profile.genderIdentity ?? ""
        showGenderIdentity = profile.genderIdentity != nil && !(profile.genderIdentity?.isEmpty ?? true)
    }

    private func save() {
        guard let age = Int(ageText.trimmingCharacters(in: .whitespaces)),
              (18...100).contains(age) else {
            errorMessage = "Please enter a valid age between 18 and 100."
            return
        }

        profile.age = age
        profile.sex = sex
        profile.smokingStatus = smokingStatus
        profile.smokingFrequency = smokingStatus.hasFrequency ? smokingFrequency.nilIfEmpty : nil
        profile.genderIdentity = showGenderIdentity ? genderIdentity.nilIfEmpty : nil
        try? modelContext.save()
        dismiss()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
