import SwiftUI

/// The pair of translucent diagonal bands the Figma lays over cards and pills, as a soft sheen.
/// Positions are measured from the top-leading corner of the view it decorates.
struct DiagonalStripes: View {
    struct Stripe {
        let center: CGPoint
        let size: CGSize
    }

    let stripes: [Stripe]
    let tint: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(stripes.indices, id: \.self) { index in
                Rectangle()
                    .fill(tint)
                    .frame(width: stripes[index].size.width, height: stripes[index].size.height)
                    .rotationEffect(.degrees(-43.33))
                    .position(stripes[index].center)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension DiagonalStripes {
    static let pill = DiagonalStripes(
        stripes: [
            Stripe(center: CGPoint(x: 67, y: 18), size: CGSize(width: 91.14, height: 14.88)),
            Stripe(center: CGPoint(x: 35.5, y: 3.7), size: CGSize(width: 91.14, height: 6.71))
        ],
        tint: .white.opacity(0.1)
    )

    static let warmCard = DiagonalStripes(
        stripes: [
            Stripe(center: CGPoint(x: 82.5, y: 58.2), size: CGSize(width: 244.1, height: 35.6)),
            Stripe(center: CGPoint(x: 27.3, y: 32.6), size: CGSize(width: 218.04, height: 16.05))
        ],
        tint: .white.opacity(0.1)
    )

    static let coolCard = DiagonalStripes(
        stripes: [
            Stripe(center: CGPoint(x: 73, y: 67.2), size: CGSize(width: 218.04, height: 35.6)),
            Stripe(center: CGPoint(x: 27.3, y: 32.6), size: CGSize(width: 218.04, height: 16.05))
        ],
        tint: Color(red: 66 / 255, green: 56 / 255, blue: 201 / 255).opacity(0.03)
    )
}
