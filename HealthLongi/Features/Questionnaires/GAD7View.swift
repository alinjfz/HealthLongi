import SwiftUI

struct GAD7View: View {
    @Binding var answers: [Int?]

    private let questions = [
        "Feeling nervous, anxious, or on edge",
        "Not being able to stop or control worrying",
        "Worrying too much about different things",
        "Trouble relaxing",
        "Being so restless that it is hard to sit still",
        "Becoming easily annoyed or irritable",
        "Feeling afraid, as if something awful might happen"
    ]

    var totalScore: Int {
        answers.compactMap { $0 }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GAD-7 Anxiety Screening")
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)

            Text("Over the last 2 weeks, how often have you been bothered by…")
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            ForEach(questions.indices, id: \.self) { index in
                LikertQuestionView(
                    question: "\(index + 1). \(questions[index])",
                    options: gad7LikertOptions,
                    selectedScore: binding(for: index)
                )
            }

            Text("Total score: \(totalScore) / 21")
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
        GAD7View(answers: .constant(Array(repeating: nil, count: 7)))
            .padding()
    }
}
