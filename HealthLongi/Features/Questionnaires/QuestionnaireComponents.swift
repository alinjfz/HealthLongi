import SwiftUI

struct QuestionOption: Identifiable {
    let id = UUID()
    let label: String
    let score: Int
}

struct LikertQuestionView: View {
    let question: String
    var footer: String? = nil
    let options: [QuestionOption]
    @Binding var selectedScore: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NHSTheme.textPrimary)

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(NHSTheme.textSecondary)
            }

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

let friendlyFrequencyOptions: [QuestionOption] = [
    QuestionOption(label: "Not really", score: 0),
    QuestionOption(label: "Some days", score: 1),
    QuestionOption(label: "More than half the days", score: 2),
    QuestionOption(label: "Most days", score: 3)
]

let phq9LikertOptions: [QuestionOption] = friendlyFrequencyOptions
let gad7LikertOptions: [QuestionOption] = friendlyFrequencyOptions

let who5Options: [QuestionOption] = [
    QuestionOption(label: "At no time", score: 0),
    QuestionOption(label: "Some of the time", score: 1),
    QuestionOption(label: "Less than half", score: 2),
    QuestionOption(label: "More than half", score: 3),
    QuestionOption(label: "Most of the time", score: 4),
    QuestionOption(label: "All of the time", score: 5)
]

let pss10Options: [QuestionOption] = [
    QuestionOption(label: "Never", score: 0),
    QuestionOption(label: "Almost never", score: 1),
    QuestionOption(label: "Sometimes", score: 2),
    QuestionOption(label: "Fairly often", score: 3),
    QuestionOption(label: "Very often", score: 4)
]

let sleepOptions: [QuestionOption] = [
    QuestionOption(label: "Not at all", score: 0),
    QuestionOption(label: "A little", score: 1),
    QuestionOption(label: "Quite a bit", score: 2),
    QuestionOption(label: "Very much", score: 3)
]

/// AUDIT-C uses 0–4 per question; options vary by question index in the view.
let auditCFrequencyOptions: [QuestionOption] = [
    QuestionOption(label: "Never", score: 0),
    QuestionOption(label: "Monthly or less", score: 1),
    QuestionOption(label: "2–4 times a month", score: 2),
    QuestionOption(label: "2–3 times a week", score: 3),
    QuestionOption(label: "4 or more times a week", score: 4)
]

let auditCDrinksOptions: [QuestionOption] = [
    QuestionOption(label: "1 or 2", score: 0),
    QuestionOption(label: "3 or 4", score: 1),
    QuestionOption(label: "5 or 6", score: 2),
    QuestionOption(label: "7 to 9", score: 3),
    QuestionOption(label: "10 or more", score: 4)
]

let auditCBingeOptions: [QuestionOption] = [
    QuestionOption(label: "Never", score: 0),
    QuestionOption(label: "Less than monthly", score: 1),
    QuestionOption(label: "Monthly", score: 2),
    QuestionOption(label: "Weekly", score: 3),
    QuestionOption(label: "Daily or almost daily", score: 4)
]

var auditCOptions: [QuestionOption] { auditCFrequencyOptions }

struct GenericLikertQuestionnaireView: View {
    let kind: QuestionnaireKind
    @Binding var answers: [Int?]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(kind.title)
                .font(.title2.bold())
                .foregroundStyle(NHSTheme.primaryBlue)

            Text(kind.intro)
                .font(.subheadline)
                .foregroundStyle(NHSTheme.textSecondary)

            if let sections = kind.contextSections {
                AuditCContextCard(sections: sections)
            }

            ForEach(kind.humanizedQuestions.indices, id: \.self) { index in
                LikertQuestionView(
                    question: kind.humanizedQuestions[index],
                    footer: kind.questionFooter(at: index),
                    options: options(for: index),
                    selectedScore: binding(for: index)
                )
            }
        }
    }

    private func options(for index: Int) -> [QuestionOption] {
        if kind == .auditC {
            switch index {
            case 0: return auditCFrequencyOptions
            case 1: return auditCDrinksOptions
            default: return auditCBingeOptions
            }
        }
        if kind == .pss10 && [3, 4, 6, 7].contains(index) {
            return pss10ReverseOptions
        }
        return kind.likertOptions
    }

    private var pss10ReverseOptions: [QuestionOption] {
        [
            QuestionOption(label: "Very often", score: 0),
            QuestionOption(label: "Fairly often", score: 1),
            QuestionOption(label: "Sometimes", score: 2),
            QuestionOption(label: "Almost never", score: 3),
            QuestionOption(label: "Never", score: 4)
        ]
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

private struct AuditCContextCard: View {
    let sections: [(title: String, body: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("About this screening", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NHSTheme.primaryBlue)

            ForEach(sections.indices, id: \.self) { index in
                let section = sections[index]
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NHSTheme.textPrimary)
                    Text(section.body)
                        .font(.caption)
                        .foregroundStyle(NHSTheme.textSecondary)
                }
            }

            Link(destination: QuestionnaireKind.auditCNHSAlcoholURL) {
                Label("NHS alcohol advice", systemImage: "arrow.up.right.square")
                    .font(.caption.weight(.medium))
            }
        }
        .nhsCard()
    }
}
