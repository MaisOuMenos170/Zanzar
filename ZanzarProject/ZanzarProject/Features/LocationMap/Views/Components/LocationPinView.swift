import SwiftUI

/// Map pin for places loaded from the backend — not the user's live location.
struct LocationPinView: View {
    let iconName: String

    private enum Metrics {
        static let width: CGFloat = 40.077
        static let height: CGFloat = 47.711
        static let innerDiameter: CGFloat = 28
        static let innerCircleCenterYOffset: CGFloat = -3.856
        static let iconSize: CGFloat = 14
    }

    init(iconName: String = "leaf") {
        self.iconName = iconName
    }

    var body: some View {
        ZStack {
            LocationPinShape()
                .fill(Color("LocationPinPrimary"))

            Circle()
                .fill(Color("LocationPinInner"))
                .frame(width: Metrics.innerDiameter, height: Metrics.innerDiameter)
                .offset(y: Metrics.innerCircleCenterYOffset)

            Image(systemName: iconName)
                .font(.system(size: Metrics.iconSize))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
                .offset(y: Metrics.innerCircleCenterYOffset)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .accessibilityHidden(true)
    }
}

#Preview {
    LocationPinView()
        .padding()
}
