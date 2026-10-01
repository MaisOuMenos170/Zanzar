import SwiftUI

/// Visual state from Figma node 860:4084 (pins e selos).
enum LocationPinStyle: Sendable {
    /// Lugar habilitado para fazer check-in — centro branco, ícone coral.
    case available
    /// Check-in já foi realizado — centro vermelho escuro, ícone branco.
    case checkedIn
    /// Check-in está no roteiro atual — pin laranja.
    case inCurrentItinerary
}

/// Map pin for places loaded from the backend — not the user's live location.
struct LocationPinView: View {
    let iconName: String
    var style: LocationPinStyle

    private enum Metrics {
        static let width: CGFloat = 46
        static let height: CGFloat = 54
        static let innerDiameter: CGFloat = 32
        static let innerCircleCenterYOffset: CGFloat = -4.4
        static let iconSize: CGFloat = 15
    }

    init(iconName: String = "leaf", style: LocationPinStyle = .available) {
        self.iconName = iconName
        self.style = style
    }

    init(category: ZanzarPlaceCategory, style: LocationPinStyle = .available) {
        self.iconName = category.pinIconName
        self.style = style
    }

    var body: some View {
        ZStack {
            LocationPinShape()
                .fill(colors.primary)

            Circle()
                .fill(colors.inner)
                .frame(width: Metrics.innerDiameter, height: Metrics.innerDiameter)
                .offset(y: Metrics.innerCircleCenterYOffset)

            Image(systemName: iconName)
                .font(.system(size: Metrics.iconSize))
                .foregroundStyle(colors.icon)
                .accessibilityHidden(true)
                .offset(y: Metrics.innerCircleCenterYOffset)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .accessibilityHidden(true)
    }

    private var colors: PinColors {
        switch style {
        case .available:
            PinColors(
                primary: Color("LocationPinPrimary"),
                inner: .white,
                icon: Color("LocationPinPrimary")
            )
        case .checkedIn:
            PinColors(
                primary: Color("LocationPinPrimary"),
                inner: Color("LocationPinCheckedInner"),
                icon: .white
            )
        case .inCurrentItinerary:
            PinColors(
                primary: Color("LocationPinItineraryPrimary"),
                inner: Color("LocationPinItineraryInner"),
                icon: .white
            )
        }
    }
}

private struct PinColors {
    let primary: Color
    let inner: Color
    let icon: Color
}

#Preview("Available") {
    HStack(spacing: 8) {
        LocationPinView(category: .restaurant)
        LocationPinView(category: .bar)
        LocationPinView(category: .cafe)
        LocationPinView(category: .museum)
    }
    .padding()
}

#Preview("Checked in") {
    HStack(spacing: 8) {
        LocationPinView(category: .park, style: .checkedIn)
        LocationPinView(category: .tourist, style: .checkedIn)
        LocationPinView(category: .party, style: .checkedIn)
    }
    .padding()
}

#Preview("In current itinerary") {
    HStack(spacing: 8) {
        LocationPinView(category: .restaurant, style: .inCurrentItinerary)
        LocationPinView(category: .historic, style: .inCurrentItinerary)
        LocationPinView(category: .curiosity, style: .inCurrentItinerary)
    }
    .padding()
}
