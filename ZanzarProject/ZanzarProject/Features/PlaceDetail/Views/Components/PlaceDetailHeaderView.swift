import SwiftUI

/// The bar above the place detail (Figma "Detalhes do lugar"): back, the screen's title and share.
struct PlaceDetailHeaderView: View {
    let onBack: () -> Void
    /// What the share sheet sends. The button is left out while there is no link to share.
    var shareURL: URL?
    /// The name of the place, as the subject and the message that go with the link.
    var shareName = ""

    var body: some View {
        HStack(spacing: 16) {
            BackButton(action: onBack)

            Text("placeDetail.header.title")
                .typography(.subtitle1)
                .foregroundStyle(Color.titleBrown)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)

            if let shareURL {
                ShareLink(item: shareURL, subject: Text(shareName), message: Text(shareName)) {
                    Label("placeDetail.shareButton.label", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(HeaderCircleButtonStyle())
            } else {
                // Keeps the title centered between two buttons.
                Color.clear
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    PlaceDetailHeaderView(onBack: {}, shareURL: URL(string: "https://example.com"))
        .background(Color.profileBackground)
}
