import SwiftUI

/// (CC BY, CC BY-SA) requires showing it next to the photo. A long author name is cut, the licence never is.
struct PlacePhotoCreditView: View {
    let credit: PhotoCredit

    var body: some View {
        Link(destination: credit.sourceURL) {
            HStack(spacing: 0) {
                Text(verbatim: credit.author)
                    .lineLimit(1)
                // The licence wraps instead of being cut, and takes space before the author name does.
                Text(verbatim: " · \(credit.license)")
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
            .font(.system(size: 9))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.black.opacity(0.55), in: .capsule)
        }
    }
}
