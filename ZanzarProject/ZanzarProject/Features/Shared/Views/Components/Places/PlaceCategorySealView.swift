import SwiftUI

/// Category seal from Figma node 860:4084 (selos por categoria de lugar).
struct PlaceCategorySealView: View {
    let category: ZanzarPlaceCategory
    var state: PlaceCategorySealState = .earned
    var size: CGFloat = 102

    var body: some View {
        Image(category.sealImageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .saturation(state == .preview ? 0 : 1)
            .opacity(state == .preview ? 0.45 : 1)
            .scaleEffect(state == .earned ? 1 : 0.92)
            .accessibilityHidden(true)
    }
}

#Preview("Earned") {
    HStack {
        PlaceCategorySealView(category: .restaurant, state: .earned)
        PlaceCategorySealView(category: .park, state: .earned, size: 72)
    }
    .padding()
}

#Preview("Preview") {
    HStack {
        PlaceCategorySealView(category: .restaurant, state: .preview)
        PlaceCategorySealView(category: .party, state: .preview, size: 72)
    }
    .padding()
}
