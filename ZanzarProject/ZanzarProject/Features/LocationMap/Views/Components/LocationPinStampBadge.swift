import SwiftUI

/// Round "visited" badge with a check mark, pinned to the top-right corner of a visited label (Figma 1929:638).
struct LocationPinStampBadge: View {
    static let size: CGFloat = 17

    var body: some View {
        Circle()
            .fill(Color("LocationPinStamp"))
            .overlay {
                // Centered 2pt border, so it bleeds 1pt outside the 17pt frame like the Figma stroke.
                Circle().stroke(.white, lineWidth: 2)
            }
            .frame(width: Self.size, height: Self.size)
            .overlay {
                // 6.6×5.5 check centered slightly right of the badge center, as drawn in Figma.
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 3))
                    path.addLine(to: CGPoint(x: 2.3, y: 5.5))
                    path.addLine(to: CGPoint(x: 6.6, y: 0))
                }
                .stroke(
                    Color("LocationPinInk"),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 6.6, height: 5.5)
                .offset(x: 0.3, y: 0.15)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    LocationPinStampBadge()
        .padding()
        .background(.blue)
}
