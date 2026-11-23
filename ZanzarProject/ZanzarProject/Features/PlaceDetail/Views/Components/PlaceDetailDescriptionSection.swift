import SwiftUI

struct PlaceDetailDescriptionSection: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("placeDetail.detailsSection.title")
                .typography(.subtitle1)
                .bold()
                .accessibilityAddTraits(.isHeader)

            Text(description)
                .typography(.body2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.brandNeutral950)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
