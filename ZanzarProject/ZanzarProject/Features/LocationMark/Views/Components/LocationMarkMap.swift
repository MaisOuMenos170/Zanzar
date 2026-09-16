import MapKit
import SwiftUI

struct LocationMarkMap: View {
    @Binding var position: MapCameraPosition
    let markedLocation: LocationMark?

    var body: some View {
        Map(position: $position) {
            if let markedLocation {
                Marker(
                    "Localização marcada",
                    systemImage: "mappin.circle.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: markedLocation.latitude,
                        longitude: markedLocation.longitude
                    )
                )
                .tint(.red)
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        guard let markedLocation else {
            return "Mapa sem localização marcada"
        }
        return "Mapa com pin na localização marcada em \(markedLocation.capturedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
