import SwiftUI

/// Stays under the search bar for as long as something is off with the map (no fresh places, a position that is not
/// precise enough), with a way to try again. A toast would vanish after a few seconds and leave a map that looks
/// empty or wrong for no reason.
struct MapNoticeBanner: View {
    let message: String
    let isRetrying: Bool
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.brandNeutral950)
                .accessibilityHidden(true)
            Text(verbatim: message)
                .scaledFont(size: 14)
                .foregroundStyle(Color.brandNeutral950)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("locationMap.retryButton.title", action: onRetry)
                .scaledFont(size: 14, weight: .semibold)
                .tint(Color.brandBlue600)
                .disabled(isRetrying)
                .frame(minHeight: 44)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .announced(message)
    }
}

#Preview {
    MapNoticeBanner(message: "Não foi possível carregar os lugares agora.", isRetrying: false) {}
        .padding()
}
