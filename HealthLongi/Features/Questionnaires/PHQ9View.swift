import SwiftUI

struct PHQ9View: View {
    @Binding var answers: [Int?]

    var body: some View {
        GenericLikertQuestionnaireView(kind: .phq9, answers: $answers)
    }
}

#Preview {
    ScrollView {
        PHQ9View(answers: .constant(Array(repeating: nil, count: 9)))
            .padding()
    }
}
