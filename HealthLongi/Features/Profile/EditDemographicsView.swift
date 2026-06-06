import SwiftUI
import SwiftData

struct EditDemographicsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var dateOfBirth = Date()
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
                    dateOfBirthSection
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

    private func loadValues() {
        dateOfBirth = profile.dateOfBirth
        sex = profile.sex
        smokingStatus = profile.smokingStatus
        smokingFrequency = profile.smokingFrequency ?? ""
        genderIdentity = profile.genderIdentity ?? ""
        showGenderIdentity = profile.genderIdentity != nil && !(profile.genderIdentity?.isEmpty ?? true)
    }

    private func save() {
        let age = ageFromDOB
        guard (18...100).contains(age) else {
            errorMessage = "Age must be between 18 and 100."
            return
        }

        profile.dateOfBirth = dateOfBirth
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
