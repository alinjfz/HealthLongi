import SwiftUI
import SwiftData

struct QuestionnaireSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let kind: QuestionnaireKind
    let profile: UserProfile?
    let modelContext: ModelContext
    var onSave: () -> Void

    @State private var answers: [Int?]
    @State private var showCompletion = false

    init(kind: QuestionnaireKind, profile: UserProfile?, modelContext: ModelContext, onSave: @escaping () -> Void) {
        self.kind = kind
        self.profile = profile
        self.modelContext = modelContext
        self.onSave = onSave
        _answers = State(initialValue: Array(repeating: nil, count: kind.questionCount))
    }

    private var isComplete: Bool { answers.allSatisfy { $0 != nil } }

    var body: some View {
        NavigationStack {
            Group {
                if showCompletion {
                    QuestionnaireCompletionView(title: kind.title) {
                        dismiss()
                    }
                } else {
                    ScrollView {
                        GenericLikertQuestionnaireView(kind: kind, answers: $answers)
                            .padding()
                    }
                    .background(NHSTheme.background)
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showCompletion {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .disabled(!isComplete)
                    }
                }
            }
        }
    }

    private func save() {
        guard let profile, isComplete else { return }
        let score = answers.compactMap { $0 }.reduce(0, +)
        profile.markQuestionnaireComplete(kind, score: score)
        try? modelContext.save()
        onSave()
        showCompletion = true
    }
}
