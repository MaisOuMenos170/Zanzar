import SwiftUI

struct PlaceDetailDirectionsButton: View {
    let latitude: Double
    let longitude: Double
    let placeName: String

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button("placeDetail.directionsButton.title", systemImage: "arrow.up.forward") {
            openDirections()
        }
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color("WelcomeSecondaryBackground"), in: .capsule)
    }

    private func openDirections() {
        let encodedName = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeName
        guard let url = URL(string: "http://maps.apple.com/?daddr=\(latitude),\(longitude)&q=\(encodedName)") else {
            return
        }
        openURL(url)
    }
}
