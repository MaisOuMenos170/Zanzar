import SwiftUI

struct PlaceDetailDirectionsButton: View {
    let latitude: Double
    let longitude: Double
    let placeName: String

    @Environment(\.openURL) private var openURL
    @State private var navigationAppOptions: PlaceDetailNavigationAppOptions?

    var body: some View {
        Button(action: showDirections) {
            HStack {
                Text("placeDetail.directionsButton.title")
                Image(systemName: "arrow.up.forward")
            }
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .sheet(item: $navigationAppOptions) { options in
            PlaceDetailNavigationAppsSheet(apps: options.apps, onSelect: openDirections)
        }
    }

    private func showDirections() {
        let apps = PlaceDetailNavigationApp.installed
        switch apps.count {
        case 0:
            // Apple Maps was removed and no other app is installed: the web link opens in the browser.
            openDirections(in: .appleMaps)
        case 1:
            openDirections(in: apps[0])
        default:
            navigationAppOptions = PlaceDetailNavigationAppOptions(apps: apps)
        }
    }

    private func openDirections(in app: PlaceDetailNavigationApp) {
        guard let url = app.directionsURL(latitude: latitude, longitude: longitude, placeName: placeName) else {
            return
        }
        openURL(url)
    }
}
