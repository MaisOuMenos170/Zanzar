import SwiftUI

/// Visual state of a map pin, from the Figma component "Pin do mapa v2" (node 1956:918).
nonisolated enum LocationPinStyle: Sendable {
    /// "Não visitado": hollow white label with a dashed indigo outline, like a stamp still to be collected.
    case available
    /// "Visitado": check-in done. Solid indigo label with a yellow check badge.
    case checkedIn
    /// "No roteiro": the stop that completes the current itinerary. Larger orange label with a white outline.
    case inCurrentItinerary

    /// A pin earns its stamp when it turns into a checked-in one, not when it is drawn that way.
    static func earnedStamp(from old: LocationPinStyle, to new: LocationPinStyle) -> Bool {
        new == .checkedIn && old != .checkedIn
    }
}

/// Map pin for places loaded from the backend — not the user's live location.
struct LocationPinView: View {
    let iconName: String
    var style: LocationPinStyle

    private static let iconSize: CGFloat = 18

    init(iconName: String = "leaf", style: LocationPinStyle = .available) {
        self.iconName = iconName
        self.style = style
    }

    init(category: ZanzarPlaceCategory, style: LocationPinStyle = .available) {
        self.iconName = category.pinIconName
        self.style = style
    }

    /// Frame of the pin in points; the tail tip touches the bottom edge, centered horizontally.
    static func size(for style: LocationPinStyle) -> CGSize {
        style == .inCurrentItinerary ? CGSize(width: 52, height: 62) : CGSize(width: 44, height: 54)
    }

    var body: some View {
        ZStack {
            label

            Image(systemName: iconName)
                .font(.system(size: Self.iconSize))
                .foregroundStyle(look.icon)
                .accessibilityHidden(true)
                .position(x: metrics.bodyCenter.x, y: metrics.bodyCenter.y)

            if style == .checkedIn {
                LocationPinStampBadge()
                    .transition(.scale(scale: 1.6).combined(with: .opacity))
                    .position(x: 41.5, y: 4.5)
            }
        }
        .frame(width: Self.size(for: style).width, height: Self.size(for: style).height)
        .motion(Motion.carimbo(duration: Motion.StampSize.small.duration), value: style)
        .haptic(.carimboLeve, trigger: style, when: { old, new in
            LocationPinStyle.earnedStamp(from: old, to: new)
        })
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
                origin: CGPoint(x: 1.25, y: 1.25),
                size: CGSize(width: 41.5, height: 51.5),
                cornerRadius: 12,
                tailWidth: 14,
                tailHeight: 9
            )
        case .inCurrentItinerary:
            LabelMetrics(
                origin: CGPoint(x: 1.5, y: 1.5),
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
                fill: .brandNeutral50,
                outline: .brandPurple600,
                outlineStyle: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3.5238, 2.6428]),
                icon: .brandPurple600
            )
        case .checkedIn:
            PinLook(
                fill: .brandPurple600,
                outline: .brandPurple600,
                outlineStyle: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round),
                icon: .brandNeutral50
            )
        case .inCurrentItinerary:
            PinLook(
                fill: .brandOrange600,
                outline: .brandNeutral50,
                outlineStyle: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round),
                icon: .brandNeutral50
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

#Preview("Pin v2") {
    VStack(spacing: 12) {
        ForEach([LocationPinStyle.available, .checkedIn, .inCurrentItinerary], id: \.self) { style in
            HStack(spacing: 8) {
                ForEach(previewCategories, id: \.self) { LocationPinView(category: $0, style: style) }
            }
        }
    }
    .padding()
}
