import SwiftUI

struct ProfileRecentCheckInsSection: View {
    let checkIns: [ProfileCheckIn]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.recentCheckIns.title")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(checkIns) { checkIn in
                    ProfileCheckInCard(checkIn: checkIn)
                }
            }
        }
    }
}

#Preview {
    ProfileRecentCheckInsSection(checkIns: ProfileCheckIn.samples)
        .padding()
}
