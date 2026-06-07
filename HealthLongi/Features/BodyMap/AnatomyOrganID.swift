import SwiftUI

/// Organ assets from the AnatomyBodyV3 reference — mapped to `BodyRegion` for health colouring.
enum AnatomyOrganID: String, CaseIterable, Identifiable {
    case brain
    case lungs
    case heart
    case liver
    case stomach
    case kidneys
    case intestines
    case bladder

    var id: String { rawValue }

    var imageName: String { "organ_\(rawValue)" }

    var bodyRegion: BodyRegion {
        switch self {
        case .brain: .brain
        case .lungs: .lungs
        case .heart: .heart
        case .liver, .stomach, .kidneys, .intestines, .bladder: .abdomen
        }
    }

    /// Neutral anatomical tint when no health signal is available for this organ.
    var restingTint: Color {
        switch self {
        case .brain: Color(red: 1.0, green: 0.75, blue: 0.70)
        case .lungs: Color(red: 1.0, green: 0.38, blue: 0.38)
        case .heart: Color(red: 1.0, green: 0.15, blue: 0.15)
        case .liver: Color(red: 0.80, green: 0.30, blue: 0.15)
        case .stomach: Color(red: 1.0, green: 0.50, blue: 0.40)
        case .kidneys: Color(red: 0.85, green: 0.40, blue: 0.25)
        case .intestines: Color(red: 1.0, green: 0.55, blue: 0.25)
        case .bladder: Color(red: 0.55, green: 0.75, blue: 1.0)
        }
    }

    /// Back → front paint order (matches AnatomyBodyV3).
    static let renderOrder: [AnatomyOrganID] = [
        .intestines, .bladder, .kidneys,
        .liver, .stomach,
        .lungs, .heart, .brain
    ]
}
