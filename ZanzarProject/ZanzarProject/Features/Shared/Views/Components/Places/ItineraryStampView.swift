import SwiftUI

/// Itinerary stamp from Figma node 860:4084 (same asset for every route in the MVP).
struct ItineraryStampView: View {
    var state: PlaceCategorySealState = .earned
    var size: CGFloat = 102

    var body: some View {
        Image("carimboRoteiro")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .saturation(state == .preview ? 0 : 1)
            .opacity(state == .preview ? 0.45 : 1)
            .scaleEffect(state == .earned ? 1 : 0.92)
            .accessibilityHidden(true)
    }
}

#Preview("Earned") {
    ItineraryStampView(state: .earned)
        .padding()
}

#Preview("Preview") {
    ItineraryStampView(state: .preview, size: 72)
        .padding()
}
