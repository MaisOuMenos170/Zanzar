import MapKit
import SwiftUI

/// A small, still map with the place's pin: enough to see it is the right corner of the city.
struct SharePlaceMap: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 600, longitudinalMeters: 600)
        Map(position: .constant(.region(region)), interactionModes: []) {
            Marker("", coordinate: coordinate)
                .tint(Color.brandPurple500)
        }
        .frame(height: 132)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.brandOptionBorder, lineWidth: 1)
        }
        .accessibilityElement()
        .accessibilityLabel("placeShare.map.accessibilityLabel")
    }
}
