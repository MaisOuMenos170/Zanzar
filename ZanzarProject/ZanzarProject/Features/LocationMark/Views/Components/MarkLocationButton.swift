import SwiftUI

struct MarkLocationButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(
            isLoading ? "Obtendo localização" : "Marcar localização",
            systemImage: "location.fill",
            action: action
        )
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isLoading)
        .accessibilityHint("Obtém a posição atual e coloca um pin no mapa")
    }
}
