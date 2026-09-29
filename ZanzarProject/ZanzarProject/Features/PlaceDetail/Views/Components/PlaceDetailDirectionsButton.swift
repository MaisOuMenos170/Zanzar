import SwiftUI

struct PlaceDetailDirectionsButton: View {
    let action: () -> Void

    var body: some View {
        Button("placeDetail.directionsButton.title", systemImage: "arrow.up.forward", action: action)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("WelcomeSecondaryBackground"), in: .capsule)
    }
}
