import SwiftUI

/// "Roteiros em destaque" card of the check-in home (Figma "checkin v2", node 1998:4128): a ticket-shaped tile with
/// how many places the roteiro has, its name, a "Ver detalhes" button and the dashed route drawing on the right.
struct ItineraryCard: View {
    let itinerary: Itinerary
    let onViewDetails: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(.checkInRouteIllustration)
                .resizable()
                .frame(width: 162, height: 101.503)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 27.62)
                .padding(.trailing, 29.5)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .accessibilityHidden(true)
                        Text("itinerary.featuredCard.places \(itinerary.placesCount)")
                            .font(.system(size: 12, design: .rounded))
                    }

                    Text(itinerary.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .frame(width: 200, alignment: .leading)
                }
                .tracking(0.15)
                .foregroundStyle(Color.brandSheetTitle)

                detailsButton
            }
            .padding(.leading, 16.5)
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 149)
        .background {
            Image(.checkInFeaturedBackground)
                .resizable()
        }
        .accessibilityElement(children: .contain)
    }

    private var detailsButton: some View {
        Button(action: onViewDetails) {
            Text("itinerary.card.viewDetails")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    ZStack {
                        Color.brandPurple500
                        CheckInDiagonalStripe(
                            bar: CGSize(width: 91.141, height: 14.883),
                            box: CGSize(width: 76.512, height: 73.363),
                            origin: CGPoint(x: 19.9, y: -17),
                            color: Self.stripeColor
                        )
                        CheckInDiagonalStripe(
                            bar: CGSize(width: 91.141, height: 6.707),
                            box: CGSize(width: 70.902, height: 67.416),
                            origin: CGPoint(x: -8.92, y: -28.45),
                            color: Self.stripeColor
                        )
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
                .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(Text(itinerary.name))
    }

    /// Indigo at 20%, the same in both bars.
    private static let stripeColor = Color(red: 66 / 255, green: 56 / 255, blue: 201 / 255).opacity(0.2)
}

#Preview {
    ItineraryCard(
        itinerary: Itinerary(
            slug: "centro-historico",
            name: "Bora passear no centro histórico?",
            category: "historic",
            routeType: .fixed,
            placesCount: 4,
            completedCount: 20,
            coverImageURL: nil
        ),
        onViewDetails: {}
    )
    .padding()
    .background(Color.brandBlue50)
}
