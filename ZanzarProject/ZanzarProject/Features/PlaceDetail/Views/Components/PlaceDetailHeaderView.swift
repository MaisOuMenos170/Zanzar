import SwiftUI

struct PlaceDetailHeaderView: View {
    let name: String
    let distanceText: String
    let openingHoursKey: String
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AuthBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(distanceText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(Color("PlaceDetailOpenStatus"))

                    Text(openingHoursKey.localizedString)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color("PlaceDetailOpenStatus"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }
}
