import Foundation

struct Profile: Hashable {
    let summary: ProfileSummary
    let recentCheckIns: [ProfileCheckIn]
}

#if DEBUG
extension Profile {
    static let preview = Profile(
        summary: ProfileSummary(name: "Ana Silva", checkInCount: 21, itineraryCount: 3, sealCount: 4),
        recentCheckIns: [
            ProfileCheckIn(id: "1", placeName: "Parque Tanguá", date: .now, photoReference: nil, sealCategory: .park),
            ProfileCheckIn(id: "2", placeName: "Museu Oscar Niemeyer", date: .now, photoReference: nil, sealCategory: .museum),
            ProfileCheckIn(id: "3", placeName: nil, date: .now, photoReference: nil, sealCategory: nil),
            ProfileCheckIn(id: "4", placeName: "Bar do Zé", date: .now, photoReference: nil, sealCategory: .bar)
        ]
    )
}
#endif
