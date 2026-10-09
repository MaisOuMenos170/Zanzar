import SwiftUI

struct ProfileRecentCheckInsSection: View {
    let checkIns: [ProfileCheckIn]
    let mediaPolicy: PlaceMediaAccessPolicy

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

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

#Preview {
    NavigationStack {
        ProfileRecentCheckInsSection(checkIns: Profile.preview.recentCheckIns, mediaPolicy: .shared)
            .padding()
    }
}

#Preview("Empty") {
    ProfileRecentCheckInsSection(checkIns: [], mediaPolicy: .shared)
        .padding()
}
