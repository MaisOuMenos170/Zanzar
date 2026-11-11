import SwiftUI

struct ProfileRecentCheckInsSection: View {
    let checkIns: [ProfileCheckIn]
    let mediaPolicy: PlaceMediaAccessPolicy

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.recentCheckIns.title")
                .font(.headline)

            if checkIns.isEmpty {
                ProfileEmptyCheckInsSheet()
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(checkIns) { checkIn in
                        NavigationLink(value: Route.placeDetail(checkIn.mapPlace)) {
                            ProfileCheckInCard(checkIn: checkIn, mediaPolicy: mediaPolicy)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("profile.checkInCard.openDetailsHint")
                    }
                }
            }
        }
    }
}
