import SwiftUI

/// The seal of a place not visited yet: a dashed ring with a "?" (Figma "checkin v2", "Ellipse 149"). The ring is
/// drawn for a seal of 83 pt and scales with `size`.
struct CheckInUnknownSealView: View {
    var size: CGFloat = 83

    var body: some View {
        ZStack {
            Image(.checkInSealUnknownRing)
                .resizable()
                .frame(width: size * 88.3916 / 83, height: size * 88.3916 / 83)
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: size * 52 / 83))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        CheckInUnknownSealView()
        CheckInUnknownSealView(size: 44.787)
    }
    .padding()
    .background(Color.brandPurple200)
}
