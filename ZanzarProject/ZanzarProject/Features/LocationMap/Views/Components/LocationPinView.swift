import SwiftUI

enum LocationPinStyle: Sendable {
    case available
    case checkedIn
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
                .fill(primaryColor)

            Circle()
                .fill(innerColor)
                .frame(width: Metrics.innerDiameter, height: Metrics.innerDiameter)
                .offset(y: Metrics.innerCircleCenterYOffset)

            Image(systemName: iconName)
                .font(.system(size: Metrics.iconSize))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
                .offset(y: Metrics.innerCircleCenterYOffset)
        }
        .frame(width: Metrics.width, height: Metrics.height)
        .accessibilityHidden(true)
    }

    private var primaryColor: Color {
        switch style {
        case .available:
            Color("LocationPinPrimary")
        case .checkedIn:
            Color("LocationPinCheckedPrimary")
        }
    }

    private var innerColor: Color {
        switch style {
        case .available:
            Color("LocationPinInner")
        case .checkedIn:
            Color("LocationPinCheckedInner")
        }
    }
}

#Preview("Available pins") {
    HStack(spacing: 8) {
        LocationPinView(category: .restaurant)
        LocationPinView(category: .bar)
        LocationPinView(category: .cafe)
        LocationPinView(category: .museum)
    }
    .padding()
}

#Preview("Checked-in pins") {
    HStack(spacing: 8) {
        LocationPinView(category: .park, style: .checkedIn)
        LocationPinView(category: .tourist, style: .checkedIn)
        LocationPinView(category: .party, style: .checkedIn)
    }
    .padding()
}
