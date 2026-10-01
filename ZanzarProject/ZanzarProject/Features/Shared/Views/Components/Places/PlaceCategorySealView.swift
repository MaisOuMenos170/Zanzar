import SwiftUI

/// Category seal from Figma node 871:5586 (selos por categoria de lugar).
struct PlaceCategorySealView: View {
    let category: ZanzarPlaceCategory
    var size: CGFloat = 102

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
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        PlaceCategorySealView(category: .restaurant)
        PlaceCategorySealView(category: .park, size: 72)
    }
    .padding()
}
