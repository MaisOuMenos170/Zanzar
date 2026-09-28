import SwiftUI

struct LocationPinView: View {
    private enum Metrics {
        static let width: CGFloat = 40.077
        static let height: CGFloat = 47.711
        static let innerDiameter: CGFloat = 28
        static let innerCircleCenterYOffset: CGFloat = -3.856
        static let iconSize: CGFloat = 14
    }

    var body: some View {
        ZStack {
            LocationPinShape()
                .fill(Color("LocationPinPrimary"))

            Circle()
                .fill(Color("LocationPinInner"))
                .frame(width: Metrics.innerDiameter, height: Metrics.innerDiameter)
                .offset(y: Metrics.innerCircleCenterYOffset)

            Image(systemName: "leaf")
                .font(.system(size: Metrics.iconSize))
                .foregroundStyle(.white)
                .offset(y: Metrics.innerCircleCenterYOffset)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .accessibilityLabel("locationMap.pin.accessibilityLabel")
    }
}

#Preview {
    LocationPinView()
        .padding()
}
