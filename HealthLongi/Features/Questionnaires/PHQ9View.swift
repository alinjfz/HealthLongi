import SwiftUI

struct PHQ9View: View {
    @Binding var answers: [Int?]

    private let questions = [
        "Little interest or pleasure in doing things",
        "Feeling down, depressed, or hopeless",
        "Trouble falling or staying asleep, or sleeping too much",
        "Feeling tired or having little energy",
        "Poor appetite or overeating",
        "Feeling bad about yourself — or that you are a failure",
        "Trouble concentrating on things",
        "Moving or speaking slowly, or being fidgety/restless",
        "Thoughts that you would be better off dead, or of hurting yourself"
    ]

    var totalScore: Int {
        answers.compactMap { $0 }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PHQ-9 Depression Screening")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Over the last 2 weeks, how often have you been bothered by…")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            ForEach(questions.indices, id: \.self) { index in
                LikertQuestionView(
                    question: "\(index + 1). \(questions[index])",
                    options: phq9LikertOptions,
                    selectedScore: binding(for: index)
                )
            }

            Text("Total score: \(totalScore) / 27")
                .font(.headline)
                .foregroundStyle(NHSTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
        }
    }

    private func binding(for index: Int) -> Binding<Int?> {
        Binding(
            get: { answers.indices.contains(index) ? answers[index] : nil },
            set: { newValue in
                while answers.count <= index { answers.append(nil) }
                answers[index] = newValue
            }
        )
    }
}

#Preview {
    ScrollView {
        PHQ9View(answers: .constant(Array(repeating: nil, count: 9)))
            .padding()
    }
}
