import SwiftUI

/// The fill of the check-in buttons: a color with two diagonal bars across it (Figma "checkin v2", "Ver detalhes"
/// and "Continuar"). It is clipped to a rounded rectangle of 16 pt.
struct StripedCapsuleBackground: View {
    let color: Color
    let stripeColor: Color

    var body: some View {
        ZStack {
            color
            DiagonalStripe(
                bar: CGSize(width: 91.141, height: 14.883),
                box: CGSize(width: 76.512, height: 73.363),
                origin: CGPoint(x: 19.9, y: -17),
                color: stripeColor
            )
            DiagonalStripe(
                bar: CGSize(width: 91.141, height: 6.707),
                box: CGSize(width: 70.902, height: 67.416),
                origin: CGPoint(x: -8.92, y: -28.45),
                color: stripeColor
            )
        }
        .clipShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    Text("Continuar")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            StripedCapsuleBackground(color: .brandOrange600, stripeColor: .black.opacity(0.02))
        }
        .padding()
}
