import SwiftUI

/// Cluster pin shown when several places overlap at the current zoom level.
struct LocationClusterPinView: View {
    let count: Int

    private enum Metrics {
        static let width: CGFloat = 40.077
        static let height: CGFloat = 47.711
        static let innerDiameter: CGFloat = 28
        static let innerCircleCenterYOffset: CGFloat = -3.856
    }

    private var scale: CGFloat {
        switch count {
        case ..<5:
            1
        case ..<10:
            1.06
        default:
            1.12
        }
    }

    private var countLabel: String {
        count > 99 ? "99+" : count.formatted()
    }

    var body: some View {
        ZStack {
            LocationPinShape()
                .fill(Color("LocationPinPrimary"))

            Circle()
                .fill(Color("LocationPinInner"))
                .frame(width: Metrics.innerDiameter, height: Metrics.innerDiameter)
                .offset(y: Metrics.innerCircleCenterYOffset)

            Text(countLabel)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
                .offset(y: Metrics.innerCircleCenterYOffset)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .scaleEffect(scale)
        .animation(.smooth(duration: 0.25), value: count)
        .animation(.smooth(duration: 0.25), value: scale)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        LocationClusterPinView(count: 3)
        LocationClusterPinView(count: 8)
        LocationClusterPinView(count: 24)
    }
    .padding()
}
