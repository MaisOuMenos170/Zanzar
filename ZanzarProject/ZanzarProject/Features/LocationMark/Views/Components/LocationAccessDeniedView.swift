import SwiftUI
import UIKit

struct LocationAccessDeniedView: View {
    @Environment(\.openURL) private var openURL
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Localização indisponível", systemImage: "location.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Tentar de novo", systemImage: "arrow.clockwise", action: retry)
            Button("Abrir Ajustes", systemImage: "gear", action: openSettings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
