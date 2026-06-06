import SwiftUI

struct GAD7View: View {
    @Binding var answers: [Int?]

    var body: some View {
        GenericLikertQuestionnaireView(kind: .gad7, answers: $answers)
    }
}

#Preview {
    ScrollView {
        GAD7View(answers: .constant(Array(repeating: nil, count: 7)))
            .padding()
    }
}
