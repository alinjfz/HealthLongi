import SwiftUI

struct TrendsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                TrendsContentView()
                    .padding()
            }
            .background(NHSTheme.background)
            .navigationTitle("Trends")
        }
    }
}

#Preview {
    TrendsView()
        .environment(\.appDependencies, .preview())
}
