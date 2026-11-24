import SwiftUI

/// The dashed box under "Check-in" while no roteiro is active (Figma "checkin v2", node 1899:3740): three clouds
/// and a hint to pick one.
struct CheckInEmptySlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(Color.checkInDashedBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .frame(height: 135)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    cloud(.checkInCloud1, size: CGSize(width: 56.9054, height: 30.1274), centerX: 77.5, centerY: 44.5)
                    cloud(.checkInCloud2, size: CGSize(width: 80.9644, height: 41.6886), centerX: 138.5, centerY: 70.3)
                    cloud(.checkInCloud3, size: CGSize(width: 57.2235, height: 30.0978), centerX: 63.7, centerY: 91.5)
                }
                .accessibilityHidden(true)
            }
            .overlay(alignment: .trailing) {
                Text("itinerary.list.empty.hint")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.checkInHint)
                    .frame(width: 128, alignment: .leading)
                    .padding(.trailing, 23)
            }
    }

    /// `centerX` and `centerY` are where the cloud's center sits inside the box.
    private func cloud(_ image: ImageResource, size: CGSize, centerX: CGFloat, centerY: CGFloat) -> some View {
        Image(image)
            .resizable()
            .frame(width: size.width, height: size.height)
            .position(x: centerX, y: centerY)
    }
}

#Preview {
    CheckInEmptySlot()
        .padding()
        .background(Color.brandBlue50)
}
