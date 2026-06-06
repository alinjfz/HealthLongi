import SwiftUI
import SwiftData

struct AppointmentPrepView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @State private var selectedConcerns: Set<String> = []
    @State private var freeText = ""
    @State private var showBrief = false
    @State private var builtBrief: GPVisitBrief?
    @State private var showConsent = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Select topics you want to discuss. Your brief will prioritise matching signals and data.")
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }

                Section("Concerns") {
                    ForEach(GPConcern.allCases) { concern in
                        Toggle(isOn: binding(for: concern)) {
                            Label(concern.label, systemImage: concern.icon)
                        }
                    }
                }

                Section("Notes for your GP") {
                    TextField("Reason for visit, symptoms, or questions…", text: $freeText, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Prepare for GP Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Preview Brief") {
                        savePrep()
                        prepareBrief()
                    }
                }
            }
            .onAppear(perform: loadExistingPrep)
            .sheet(isPresented: $showConsent) {
                GPBriefConsentSheet {
                    GPBriefConsent.grant()
                    showConsent = false
                    showBrief = true
                }
            }
            .sheet(isPresented: $showBrief) {
                if let builtBrief {
                    GPVisitBriefView(brief: builtBrief, profile: profile)
                }
            }
        }
    }

    private func binding(for concern: GPConcern) -> Binding<Bool> {
        Binding(
            get: { selectedConcerns.contains(concern.rawValue) },
            set: { isOn in
                if isOn { selectedConcerns.insert(concern.rawValue) }
                else { selectedConcerns.remove(concern.rawValue) }
            }
        )
    }

    private func loadExistingPrep() {
        guard let prep = profile.personalHealthContext?.appointmentPrep else { return }
        selectedConcerns = Set(prep.selectedConcerns)
        freeText = prep.freeTextNotes
    }

    private func savePrep() {
        var context = profile.personalHealthContext ?? .empty
        context.appointmentPrep = AppointmentPrepContext(
            selectedConcerns: Array(selectedConcerns),
            freeTextNotes: freeText,
            updatedAt: .now
        )
        profile.personalHealthContext = context
        try? modelContext.save()
    }

    private func prepareBrief() {
        guard let context = profile.personalHealthContext else { return }
        Task {
            let questions = await dependencies.onDeviceHealthAI.suggestGPQuestions(from: context)
            builtBrief = GPBriefBuilder.build(
                profile: profile,
                context: context,
                suggestedQuestions: questions
            )
            if GPBriefConsent.isGiven {
                showBrief = true
            } else {
                showConsent = true
            }
        }
    }
}
