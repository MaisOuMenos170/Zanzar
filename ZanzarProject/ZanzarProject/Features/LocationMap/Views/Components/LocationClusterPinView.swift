import SwiftUI

/// Stack-of-labels badge shown when several places overlap at the current zoom level (Figma 1930:525).
struct LocationClusterPinView: View {
    let count: Int

    /// Frame of the Figma cluster; the front label's tail tip touches the bottom edge.
    static let size = CGSize(width: 72, height: 76)

    private static let frontSize = CGSize(width: 50, height: 62)

    private var countLabel: String {
        count > 99 ? "99+" : count.formatted()
    }

    var body: some View {
        ZStack {
            backLabel(color: Color("LocationPinClusterBack"))
                .position(x: 42, y: 32)
            backLabel(color: Color("LocationPinClusterMid"))
                .position(x: 38.5, y: 35.5)

            frontLabel
                .position(x: 35, y: 44)

            Text(countLabel)
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                // The badge is a fixed-size map marker, so its count scales only up to a point and then shrinks to fit.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .frame(width: 40)
                .position(x: 35, y: 39)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(.rect)
        .accessibilityHidden(true)
    }

    private func backLabel(color: Color) -> some View {
        LocationLabelShape(cornerRadius: 13, tailWidth: 0, tailHeight: 0)
            .fill(color)
            .overlay {
                LocationLabelShape(cornerRadius: 13, tailWidth: 0, tailHeight: 0)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            }
            .frame(width: 50, height: 52)
    }

    private var frontLabel: some View {
        LocationLabelShape(cornerRadius: 13, tailWidth: 14, tailHeight: 10)
            .fill(Color("LocationPinPrimary"))
            .overlay {
                LocationLabelShape(cornerRadius: 13, tailWidth: 14, tailHeight: 10)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            .frame(width: Self.frontSize.width, height: Self.frontSize.height)
    }
}

#Preview {
    HStack(spacing: 8) {
        LocationClusterPinView(count: 2)
        LocationClusterPinView(count: 5)
        LocationClusterPinView(count: 12)
        LocationClusterPinView(count: 48)
        LocationClusterPinView(count: 150)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
