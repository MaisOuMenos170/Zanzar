import Foundation

enum Route: Hashable {
    case signUp
    case login
    case placeDetail(MapPlace)
}

enum Sheet: Identifiable, Hashable {
    case itineraryDetail(slug: String)

    var id: Self { self }
}
