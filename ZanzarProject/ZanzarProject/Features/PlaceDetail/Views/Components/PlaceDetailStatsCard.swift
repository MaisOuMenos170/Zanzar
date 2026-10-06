import SwiftUI

struct PlaceDetailStatsCard: View {
    let totalCheckIns: Int
    let category: ZanzarPlaceCategory
    let hasCheckedIn: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sealState: PlaceCategorySealState {
        hasCheckedIn ? .earned : .preview
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(totalCheckIns, format: .number)
                    .contentTransition(.numericText(value: Double(totalCheckIns)))
                    .animation(reduceMotion ? nil : .default, value: totalCheckIns)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("placeDetail.statsCard.totalCheckInsLabel")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            PlaceCategorySealView(category: category, state: sealState)
                .frame(width: 102, height: 102)
                .accessibilityLabel(sealAccessibilityLabel)
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: hasCheckedIn)
        .padding(.horizontal, 36)
        .padding(.vertical, 16)
        .background(Color("PlaceDetailStatsBackground"), in: .rect(cornerRadius: 16))
    }

    private var categoryLabel: String {
        switch category {
        case .restaurant:
            String(localized: "placeDetail.tag.restaurant")
        case .bar:
            String(localized: "placeDetail.tag.bar")
        case .cafe:
            String(localized: "placeDetail.tag.cafe")
        case .museum:
            String(localized: "placeDetail.tag.museum")
        case .park:
            String(localized: "placeDetail.tag.park")
        case .tourist:
            String(localized: "placeDetail.tag.touristSpot")
        case .historic:
            String(localized: "placeDetail.tag.historic")
        case .curiosity:
            String(localized: "placeDetail.tag.curiosity")
        case .party:
            String(localized: "placeDetail.tag.party")
        case .unknown:
            String(localized: "placeDetail.statsCard.categoryUnknown")
        }
    }

    private var sealAccessibilityLabel: String {
        if hasCheckedIn {
            String(format: String(localized: "placeDetail.statsCard.sealEarnedAccessibilityLabel"), categoryLabel)
        } else {
            String(format: String(localized: "placeDetail.statsCard.sealPreviewAccessibilityLabel"), categoryLabel)
        }
    }
}

#Preview("Before check-in") {
    PlaceDetailStatsCard(
        totalCheckIns: 42,
        category: .restaurant,
        hasCheckedIn: false
    )
    .padding()
}

#Preview("After check-in") {
    PlaceDetailStatsCard(
        totalCheckIns: 43,
        category: .restaurant,
        hasCheckedIn: true
    )
    .padding()
}

#Preview("Before check-in") {
    PlaceDetailStatsCard(
        totalCheckIns: 42,
        category: .restaurant,
        hasCheckedIn: false
    )
    .padding()
}

#Preview("After check-in") {
    PlaceDetailStatsCard(
        totalCheckIns: 43,
        category: .restaurant,
        hasCheckedIn: true
    )
    .padding()
}
