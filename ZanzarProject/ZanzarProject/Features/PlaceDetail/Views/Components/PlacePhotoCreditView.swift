import SwiftUI

/// "Photo: author · licence", linking to the photo's page at its source. The licence of the photos
/// (CC BY, CC BY-SA) requires showing it next to the photo. A long author name is cut, the licence never is.
struct PlacePhotoCreditView: View {
    let credit: PhotoCredit

    var body: some View {
        Link(destination: credit.sourceURL) {
            HStack(spacing: 0) {
                Text(L10n.string("placeDetail.photo.credit", credit.author))
                    .lineLimit(1)
                Text(" · \(credit.license)")
                    .lineLimit(1)
                    .fixedSize()
            }
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.55), in: .capsule)
        }
    }
}
