import SwiftUI

/// Visual state of a map pin, from Figma pin family B "Etiqueta carimbo" (node 1929:462).
nonisolated enum LocationPinStyle: Sendable {
    /// "Novo": not visited yet. Hollow white label with a dashed indigo outline, like a stamp still to be collected.
    case available
    /// "Visitado": check-in done. Solid indigo label with a yellow check badge.
    case checkedIn
    /// "Completa o roteiro": the stop that finishes the current itinerary. Larger orange label with a finish flag.
    case inCurrentItinerary
}

/// Map pin for places loaded from the backend — not the user's live location.
struct LocationPinView: View {
    let iconName: String
    var style: LocationPinStyle

    /// Frame shared by all three states; the tail tip touches the bottom edge, centered horizontally.
    static let size = CGSize(width: 64, height: 76)

    private static let iconSize: CGFloat = 17

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
            if style == .inCurrentItinerary {
                LocationPinFlag()
                    .position(x: 47, y: 8.75)
            }

            label

            Image(systemName: iconName)
                .font(.system(size: Self.iconSize))
                .foregroundStyle(look.icon)
                .accessibilityHidden(true)
                .position(x: metrics.bodyCenter.x, y: metrics.bodyCenter.y)

            if style == .checkedIn {
                LocationPinStampBadge()
                    .position(x: 54, y: 26)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .accessibilityHidden(true)
    }

    private var label: some View {
        LocationLabelShape(
            cornerRadius: metrics.cornerRadius,
            tailWidth: metrics.tailWidth,
            tailHeight: metrics.tailHeight
        )
        .fill(look.fill)
        .overlay {
            LocationLabelShape(
                cornerRadius: metrics.cornerRadius,
                tailWidth: metrics.tailWidth,
                tailHeight: metrics.tailHeight
            )
            .stroke(look.outline, style: look.outlineStyle)
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
        .contentShape(
            LocationLabelShape(
                cornerRadius: metrics.cornerRadius,
                tailWidth: metrics.tailWidth,
                tailHeight: metrics.tailHeight
            )
        )
        .position(x: metrics.origin.x + metrics.size.width / 2, y: metrics.origin.y + metrics.size.height / 2)
    }

    private var metrics: LabelMetrics {
        switch style {
        case .available, .checkedIn:
            LabelMetrics(
                origin: CGPoint(x: 11.25, y: 23.25),
                size: CGSize(width: 41.5, height: 51.5),
                cornerRadius: 12,
                tailWidth: 14,
                tailHeight: 9
            )
        case .inCurrentItinerary:
            LabelMetrics(
                origin: CGPoint(x: 7.5, y: 15.5),
                size: CGSize(width: 49, height: 59),
                cornerRadius: 14,
                tailWidth: 16,
                tailHeight: 10
            )
        }
    }

    private var look: PinLook {
        switch style {
        case .available:
            PinLook(
                fill: .white,
                outline: Color("LocationPinPrimary"),
                outlineStyle: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [4.93, 4.32]),
                icon: Color("LocationPinPrimary")
            )
        case .checkedIn:
            PinLook(
                fill: Color("LocationPinPrimary"),
                outline: Color("LocationPinPrimary"),
                outlineStyle: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round),
                icon: .white
            )
        case .inCurrentItinerary:
            PinLook(
                fill: Color("LocationPinItineraryPrimary"),
                outline: Color("LocationPinInk"),
                outlineStyle: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round),
                icon: Color("LocationPinInk")
            )
        }
    }
}

private struct LabelMetrics {
    let origin: CGPoint
    let size: CGSize
    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat

    /// Center of the rounded body, above the tail.
    var bodyCenter: CGPoint {
        CGPoint(x: origin.x + size.width / 2, y: origin.y + (size.height - tailHeight) / 2)
    }
}

private struct PinLook {
    let fill: Color
    let outline: Color
    let outlineStyle: StrokeStyle
    let icon: Color
}

private let previewCategories: [ZanzarPlaceCategory] = [
    .restaurant, .bar, .cafe, .museum, .park, .tourist, .historic, .curiosity, .party
]

#Preview("Novo") {
    HStack(spacing: 0) {
        ForEach(previewCategories, id: \.self) { LocationPinView(category: $0) }
    }
    .padding()
}

#Preview("Visitado") {
    HStack(spacing: 0) {
        ForEach(previewCategories, id: \.self) { LocationPinView(category: $0, style: .checkedIn) }
    }
    .padding()
}

#Preview("Completa o roteiro") {
    HStack(spacing: 0) {
        ForEach(previewCategories, id: \.self) { LocationPinView(category: $0, style: .inCurrentItinerary) }
    }
    .padding()
}
