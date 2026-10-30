import SwiftUI

/// "Photo: author · licence", linking to the photo's page at its source. The licence of the photos
/// (CC BY, CC BY-SA) requires showing it next to the photo.
struct PlacePhotoCreditView: View {
    let credit: PhotoCredit

    var body: some View {
        Link(destination: credit.sourceURL) {
            Text(L10n.string("placeDetail.photo.credit", credit.author, credit.license))
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.55), in: .capsule)
        }
    }
}
