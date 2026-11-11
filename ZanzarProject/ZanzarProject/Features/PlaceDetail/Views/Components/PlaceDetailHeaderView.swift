import SwiftUI

struct PlaceDetailHeaderView: View {
    let name: String
    let distanceText: String?
    let walkingTimeText: String?
    let openingHoursText: String
    let isOpen: Bool?
    let onBack: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            BackButton(action: onBack)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                if let distanceText {
                    Text(distanceText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }

                if let walkingTimeText {
                    Label(walkingTimeText, systemImage: "figure.walk")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Label(openingHoursText, systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }

    private var statusColor: Color {
        switch isOpen {
        case true: return Color("PlaceDetailOpenStatus")
        case false: return Color("PlaceDetailClosedStatus")
        case nil: return Color("PlaceDetailOpenStatus")
        }
    }
}
