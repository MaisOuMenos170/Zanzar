import SwiftUI

/// Finish flag on top of the "completes the itinerary" label (Figma 1929:684 and 1929:685): a 14.5pt pole with
/// a 14×8 pennant at its top. Its frame is 14×14.5, pole on the leading edge.
struct LocationPinFlag: View {
    static let size = CGSize(width: 14, height: 14.5)

    private static let pennant: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 14, y: 4))
        path.addLine(to: CGPoint(x: 0, y: 8))
        path.closeSubpath()
        return path
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: 0, y: Self.size.height))
            }
            .stroke(Color("LocationPinInk"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Self.pennant
                .fill(Color("LocationPinInk"))
            Self.pennant
                .stroke(Color("LocationPinInk"), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

#Preview {
    LocationPinFlag()
        .padding()
}
