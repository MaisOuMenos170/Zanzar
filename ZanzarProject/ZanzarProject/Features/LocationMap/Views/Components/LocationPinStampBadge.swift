import SwiftUI

/// Round "visited" badge with a check mark, pinned to the top-right corner of a visited label
/// (Figma "Pin do mapa v2": selo 17×17 and a 6,6×5,5 check).
struct LocationPinStampBadge: View {
    static let size: CGFloat = 17

    var body: some View {
        Circle()
            .fill(Color.brandYellow500)
            .overlay {
                // Centered 2pt border, so it bleeds 1pt outside the 17pt frame like the Figma stroke.
                Circle().stroke(Color.brandNeutral50, lineWidth: 2)
            }
            .frame(width: Self.size, height: Self.size)
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 3))
                    path.addLine(to: CGPoint(x: 2.3, y: 5.5))
                    path.addLine(to: CGPoint(x: 6.6, y: 0))
                }
                .stroke(
                    Color.brandPurple600,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 6.6, height: 5.5)
                .offset(x: 0.1, y: 0.15)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    LocationPinStampBadge()
        .padding()
        .background(.blue)
}
