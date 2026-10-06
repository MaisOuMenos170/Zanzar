import SwiftUI

/// Category seal from Figma node 871:5586 (selos por categoria de lugar).
struct PlaceCategorySealView: View {
    let category: ZanzarPlaceCategory
    var state: PlaceCategorySealState = .earned
    var size: CGFloat = 102

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var innerDiameter: CGFloat { size * (70.496 / 103.624) }
    private var iconSize: CGFloat { size * (37 / 103.624) }

    var body: some View {
        ZStack {
            Image("PlaceCategorySealShadow")
                .resizable()
                .scaledToFit()
                .offset(x: size * 0.019, y: size * 0.019)

            Image("PlaceCategorySealBody")
                .resizable()
                .scaledToFit()

            Circle()
                .fill(Color("PlaceCategorySealInnerFill"))
                .frame(width: innerDiameter, height: innerDiameter)

            Image(systemName: category.pinIconName)
                .font(.system(size: iconSize))
                .foregroundStyle(Color("PlaceDetailTagGreen"))
                .accessibilityHidden(true)
        }
        .frame(width: size, height: size)
        .saturation(state == .preview ? 0 : 1)
        .opacity(state == .preview ? 0.45 : 1)
        .scaleEffect(state == .earned ? 1 : 0.92)
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: state == .earned)
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
