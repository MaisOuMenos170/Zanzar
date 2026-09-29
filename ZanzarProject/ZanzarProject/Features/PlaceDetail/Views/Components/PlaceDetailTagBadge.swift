import SwiftUI

struct PlaceDetailTagBadge: View {
    let labelKey: String
    let style: PlaceDetailTagStyle

    var body: some View {
        Text(labelKey.localizedString)
            .font(.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(backgroundColor, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(foregroundColor, lineWidth: 1)
            }
    }

    private var foregroundColor: Color {
        switch style {
        case .park:
            Color("PlaceDetailTagGreen")
        case .touristSpot:
            Color("PlaceDetailTagOrange")
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .park:
            Color("PlaceDetailTagGreenBackground")
        case .touristSpot:
            Color("PlaceDetailTagOrangeBackground")
        }
    }
}
