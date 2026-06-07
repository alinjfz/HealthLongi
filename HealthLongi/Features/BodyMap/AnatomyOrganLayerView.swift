import SwiftUI

/// Single organ PNG layer tinted with a health-risk colour (AnatomyBodyV3 technique).
struct AnatomyOrganLayerView: View {
    let organ: AnatomyOrganID
    let tintColor: Color
    let tintOpacity: Double

    var body: some View {
        ZStack {
            Image(organ.imageName)
                .resizable()
                .scaledToFill()
                .blendMode(.screen)

            Rectangle()
                .fill(tintColor.opacity(tintOpacity))
                .blendMode(.color)
        }
    }
}
