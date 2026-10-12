import SwiftUI

struct PlaceDetailDescriptionSection: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("placeDetail.detailsSection.title")
                .font(.headline)
                .bold()
                .foregroundStyle(.primary)

            Text(description)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
