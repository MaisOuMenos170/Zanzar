import SwiftUI

struct PlaceDetailDirectionsButton: View {
    let latitude: Double
    let longitude: Double
    let placeName: String

    @Environment(\.openURL) private var openURL
    @State private var navigationAppOptions: PlaceDetailNavigationAppOptions?
    @State private var pendingNavigationApp: PlaceDetailNavigationApp?

    var body: some View {
        Button(action: showDirections) {
            Label("placeDetail.directionsButton.title", systemImage: "arrow.up.forward")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .sheet(item: $navigationAppOptions, onDismiss: openPendingNavigationApp) { options in
            PlaceDetailNavigationAppsSheet(apps: options.apps) { app in
                pendingNavigationApp = app
            }
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

    /// The URL is opened only once the sheet is fully dismissed: opening it while the sheet is
    /// still being torn down can make the system ignore the request.
    private func openPendingNavigationApp() {
        guard let app = pendingNavigationApp else { return }
        pendingNavigationApp = nil
        openDirections(in: app)
    }

    private func openDirections(in app: PlaceDetailNavigationApp) {
        guard let url = app.directionsURL(latitude: latitude, longitude: longitude, placeName: placeName) else {
            AppLog.placeDetail.error("Failed to build directions URL app=\(app.rawValue)")
            return
        }
        openURL(url)
    }
}
