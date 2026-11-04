import Foundation

enum Route: Hashable {
    case signUp
    case login
    case placeDetail(MapPlace)
    case avatar
    case myPhotos
    case photoPrivacy
}

enum Sheet: Identifiable, Hashable {
    case itineraryDetail(slug: String)
    case suggestPlace

    var id: Self { self }
}
