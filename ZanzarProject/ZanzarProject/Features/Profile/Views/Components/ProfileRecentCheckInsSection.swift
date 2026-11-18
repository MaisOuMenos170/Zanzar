import SwiftUI

struct ProfileRecentCheckInsSection: View {
    let checkIns: [ProfileCheckIn]
    let onSeeMore: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProfileSectionHeader(title: "profile.recentCheckIns.title", onSeeMore: onSeeMore)

            if checkIns.isEmpty {
                ListEmptyState(message: "profile.recentCheckIns.empty")
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(checkIns.enumerated()), id: \.element.id) { index, checkIn in
                        NavigationLink(value: Route.placeDetail(checkIn.mapPlace)) {
                            ProfileCheckInCard(checkIn: checkIn, tone: .tone(at: index))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityHint("profile.checkInCard.openDetailsHint")
                    }
                }
            }
        }
    }
}
