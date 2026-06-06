import SwiftUI
import SwiftData

struct QuestionnaireFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var step = 0
    @State private var phq9Answers: [Int?] = Array(repeating: nil, count: 9)
    @State private var gad7Answers: [Int?] = Array(repeating: nil, count: 7)
    @State private var bmi: Double?
    @State private var weightKg: Double?
    @State private var heightCm: Double?
    @State private var activityMinutes = 60
    @State private var savedMessage: String?

    private var phq9Complete: Bool { phq9Answers.allSatisfy { $0 != nil } }
    private var gad7Complete: Bool { gad7Answers.allSatisfy { $0 != nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    progressIndicator

                    switch step {
                    case 0:
                        PHQ9View(answers: $phq9Answers)
                    case 1:
                        GAD7View(answers: $gad7Answers)
                    default:
                        MetabolicInputView(
                            bmi: $bmi,
                            weightKg: $weightKg,
                            heightCm: $heightCm,
                            physicalActivityMinutes: $activityMinutes,
                            healthSnapshot: .empty
                        )
                    }

                    navigationButtons

                    if let savedMessage {
                        Text(savedMessage)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Health Assessment")
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index <= step ? NHSTheme.primaryBlue : NHSTheme.lightBlue)
                    .frame(height: 4)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .buttonStyle(.bordered)
            }

            Spacer()

            if step < 2 {
                Button("Next") { step += 1 }
                    .buttonStyle(NHSPrimaryButtonStyle())
                    .disabled(step == 0 ? !phq9Complete : !gad7Complete)
                    .frame(maxWidth: 160)
            } else {
                Button("Save Responses") { saveResponses() }
                    .buttonStyle(NHSPrimaryButtonStyle())
                    .disabled(bmi == nil)
                    .frame(maxWidth: 200)
            }
        }
    }

    private func saveResponses() {
        guard let profile = profiles.first else { return }
        profile.markQuestionnaireComplete(.phq9, score: phq9Answers.compactMap { $0 }.reduce(0, +))
        profile.markQuestionnaireComplete(.gad7, score: gad7Answers.compactMap { $0 }.reduce(0, +))
        profile.bmi = bmi
        profile.weightKg = weightKg
        profile.heightCm = heightCm
        profile.physicalActivityMinutes = activityMinutes
        try? modelContext.save()
        savedMessage = "Responses saved. Run assessment from Dashboard."
    }
}

#Preview {
    QuestionnaireFlowView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
