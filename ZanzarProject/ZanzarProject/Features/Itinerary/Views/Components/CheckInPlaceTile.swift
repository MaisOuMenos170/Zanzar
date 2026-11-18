import SwiftUI

/// One "Lugares próximos" tile of the check-in home (Figma "checkin v2", node 1899:3824): the place's name and
/// distance, a white arrow pill and, in the corner, its seal if it was visited or a dashed "?" if not.
struct CheckInPlaceTile: View {
    /// The four colors of the grid, in reading order; Figma alternates them.
    enum Palette: CaseIterable {
        case yellow, lavender, periwinkle, amber

        init(position: Int) {
            self = Self.allCases[position % Self.allCases.count]
        }

        var background: Color {
            switch self {
            case .yellow: .checkInTileYellow
            case .lavender: .checkInTileLavender
            case .periwinkle: .checkInTilePeriwinkle
            case .amber: .checkInTileAmber
            }
        }

        /// The warm tiles get white bars, the cool ones faint indigo ones.
        var isWarm: Bool { self == .yellow || self == .amber }

        var chevron: Color { isWarm ? .checkInChevronAmber : .checkInChevronIndigo }
    }

    let place: MapPlace
    let palette: Palette
    /// Figma places the seal a little lower on the second row.
    var isSecondRow = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .tracking(0.1)
                        .lineLimit(1)

                    if let distance = place.roundedDistanceText {
                        Text("itinerary.tile.distance \(distance)")
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(Color.brandNeutral950)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.chevron)
                    .frame(width: 58, height: 39)
                    .background(Color.brandNeutral50, in: .capsule)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                ZStack {
                    palette.background
                    stripes
                }
            }
            .overlay(alignment: .bottomTrailing) {
                seal
                    .offset(x: isSecondRow ? 6.9 : 9.1, y: isSecondRow ? 21.5 : 14.5)
                    .accessibilityHidden(true)
            }
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private var stripes: some View {
        let indigo = Color(red: 66 / 255, green: 56 / 255, blue: 201 / 255)
        let color = palette.isWarm ? Color.white.opacity(0.1) : indigo.opacity(0.03)
        let thickBar = palette.isWarm ? CGSize(width: 244.095, height: 35.604) : CGSize(width: 218.039, height: 35.604)
        let thickBox = palette.isWarm ? CGSize(width: 201.997, height: 193.389) : CGSize(width: 183.043, height: 175.51)
        let thickOrigin = palette.isWarm ? CGPoint(x: -18.54, y: -38.48) : CGPoint(x: -18.54, y: -20.6)

        DiagonalStripe(bar: thickBar, box: thickBox, origin: thickOrigin, color: color)
        DiagonalStripe(
            bar: CGSize(width: 218.039, height: 16.045),
            box: CGSize(width: 169.622, height: 161.281),
            origin: CGPoint(x: -57.5, y: -48),
            color: color
        )
    }

    @ViewBuilder
    private var seal: some View {
        if place.pinStyle == .checkedIn {
            PlaceCategorySealView(category: place.category, state: .earned, size: 83)
        } else {
            ZStack {
                Image(.checkInSealUnknownRing)
                    .resizable()
                    .frame(width: 88.3916, height: 88.3916)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(width: 83, height: 83)
        }
    }
}

#Preview {
    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
            CheckInPlaceTile(
                place: MapPlace(
                    id: "1", name: "Jardim Botânico", latitude: 0, longitude: 0,
                    category: .park, distanceMeters: 500, pinStyle: .checkedIn
                ),
                palette: .yellow
            ) {}
            CheckInPlaceTile(
                place: MapPlace(
                    id: "2", name: "Museu Oscar Niemeyer", latitude: 0, longitude: 0,
                    category: .museum, distanceMeters: 1300
                ),
                palette: .lavender
            ) {}
        }
    }
    .padding()
    .background(Color.brandBlue50)
}
