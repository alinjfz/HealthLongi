import SwiftUI
import SwiftData

struct AppointmentPrepView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \RiskAssessment.timestamp, order: .reverse) private var assessments: [RiskAssessment]

    @State private var selectedConcerns: Set<String> = []
    @State private var freeText = ""
    @State private var showBrief = false
    @State private var builtBrief: GPVisitBrief?
    @State private var showConsent = false
    @State private var isBuilding = false

    var body: some View {
        Form {
            Section {
                Text("Select topics you want to discuss. Your brief will prioritise matching data from your device.")
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
            ToolbarItem(placement: .confirmationAction) {
                Button("Preview Brief") {
                    savePrep()
                    prepareBrief()
                }
                .disabled(isBuilding)
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
                GPVisitBriefView(brief: builtBrief)
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
        guard let prep = profile.appointmentPrep else { return }
        selectedConcerns = Set(prep.selectedConcerns)
        freeText = prep.freeTextNotes
    }

    private func savePrep() {
        profile.appointmentPrep = AppointmentPrepContext(
            selectedConcerns: Array(selectedConcerns),
            freeTextNotes: freeText,
            updatedAt: .now
        )
        try? modelContext.save()
    }

    private func prepareBrief() {
        isBuilding = true
        Task {
            defer { isBuilding = false }

            let snapshot = try? await dependencies.healthDataProvider.fetchWeeklySnapshot()
            let assessment = assessments.first
            builtBrief = GPBriefBuilder.build(
                profile: profile,
                assessment: assessment,
                aiSummary: assessment?.aiInsight,
                snapshot: snapshot,
                prep: profile.appointmentPrep
            )

            if GPBriefConsent.isGiven {
                showBrief = true
            } else {
                showConsent = true
            }
        }
    }
}
