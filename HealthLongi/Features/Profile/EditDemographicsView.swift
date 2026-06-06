import SwiftUI
import SwiftData

struct EditDemographicsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var smokingStatus: SmokingStatus = .never
    @State private var smokingFrequency = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This is not stored in Apple Health. Update your smoking habit here.")
                        .font(.subheadline)
                        .foregroundStyle(NHSTheme.textSecondary)

                    smokingSection

                    Button("Save") { save() }
                        .buttonStyle(NHSPrimaryButtonStyle())
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Smoking habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadValues() }
        }
    }

    private var smokingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

    private func loadValues() {
        smokingStatus = profile.smokingStatus
        smokingFrequency = profile.smokingFrequency ?? ""
    }

    private func save() {
        profile.smokingStatus = smokingStatus
        profile.smokingFrequency = smokingStatus.hasFrequency ? smokingFrequency.nilIfEmpty : nil
        try? modelContext.save()
        dismiss()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
