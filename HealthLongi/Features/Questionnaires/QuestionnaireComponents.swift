import SwiftUI

struct QuestionOption: Identifiable {
    let id = UUID()
    let label: String
    let score: Int
}

struct LikertQuestionView: View {
    let question: String
    let options: [QuestionOption]
    @Binding var selectedScore: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NHSTheme.textPrimary)

            ForEach(options) { option in
                Button {
                    selectedScore = option.score
                } label: {
                    HStack {
                        Text(option.label)
                            .foregroundStyle(NHSTheme.textPrimary)
                        Spacer()
                        if selectedScore == option.score {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(NHSTheme.primaryBlue)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        selectedScore == option.score
                            ? NHSTheme.lightBlue
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .nhsCard()
    }
}

let phq9LikertOptions: [QuestionOption] = [
    QuestionOption(label: "Not at all", score: 0),
    QuestionOption(label: "Several days", score: 1),
    QuestionOption(label: "More than half the days", score: 2),
    QuestionOption(label: "Nearly every day", score: 3)
]

let gad7LikertOptions: [QuestionOption] = [
    QuestionOption(label: "Not at all", score: 0),
    QuestionOption(label: "Several days", score: 1),
    QuestionOption(label: "More than half the days", score: 2),
    QuestionOption(label: "Nearly every day", score: 3)
]
