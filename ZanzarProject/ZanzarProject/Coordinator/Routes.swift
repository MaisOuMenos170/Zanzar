import Foundation

enum Route: Hashable {
    case signUp
    case login
    case placeDetail(MapPlace)
    case myPhotos
    case photoPrivacy
}

enum Sheet: Identifiable, Hashable {
    case itineraryDetail(slug: String)

    var id: Self { self }
}
