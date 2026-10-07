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
            ProfileCheckIn(id: "1", placeID: "place-1", placeName: "Parque Tanguá", date: .now, photoReference: nil, sealCategory: .park, impressionTag: .happy),
            ProfileCheckIn(id: "2", placeID: "place-2", placeName: "Museu Oscar Niemeyer", date: .now, photoReference: nil, sealCategory: .museum, impressionTag: .delighted),
            ProfileCheckIn(id: "3", placeID: "place-3", placeName: nil, date: .now, photoReference: nil, sealCategory: nil, impressionTag: nil),
            ProfileCheckIn(id: "4", placeID: "place-4", placeName: "Bar do Zé", date: .now, photoReference: nil, sealCategory: .bar, impressionTag: nil)
        ]
    )
}
#endif
