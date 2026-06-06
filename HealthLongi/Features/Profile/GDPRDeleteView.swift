import SwiftUI
import SwiftData

struct GDPRDeleteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var assessments: [RiskAssessment]

    @State private var confirmationText = ""
    @State private var didDelete = false

    private var canDelete: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces) == "DELETE"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    warningSection
                    deletionListSection
                    gdprInfoSection
                    confirmationSection

                    Button("Delete All My Data", role: .destructive) {
                        deleteAllData()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!canDelete)
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Delete My Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Data Deleted", isPresented: $didDelete) {
                Button("OK") { dismiss() }
            } message: {
                Text("All your data has been removed from this device. To revoke HealthKit access, go to Settings → Health → Data Access.")
            }
        }
    }

    private var warningSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("This action cannot be undone")
                    .font(.headline)
                Text("All locally stored health data will be permanently deleted.")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
    }

    private var deletionListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What will be deleted")
                .font(.headline)
            ForEach([
                "Your profile and demographics",
                "All assessment results",
                "AI-generated summaries",
                "Questionnaire responses and lab data"
            ], id: \.self) { item in
                Label(item, systemImage: "trash")
                    .font(.subheadline)
                    .foregroundStyle(NHSTheme.textSecondary)
            }
        }
        .nhsCard()
    }

    private var gdprInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your rights")
                .font(.headline)
            Text("Under GDPR, you have the right to erasure of your personal data. This app stores all data locally on your device — deleting here removes everything from this app.")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)
            Text("Revoking HealthKit access must be done separately in iOS Settings.")
                .font(.caption)
                .foregroundStyle(NHSTheme.textSecondary)
        }
        .nhsCard()
    }

    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type DELETE to confirm")
                .font(.headline)
            TextField("DELETE", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
        }
        .nhsCard()
    }

    private func deleteAllData() {
        for assessment in assessments {
            modelContext.delete(assessment)
        }
        for profile in profiles {
            modelContext.delete(profile)
        }
        try? modelContext.save()
        didDelete = true
    }
}
