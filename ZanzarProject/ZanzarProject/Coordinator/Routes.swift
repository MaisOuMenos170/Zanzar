import Foundation

enum Route: Hashable {
    case signUp
    case login
    case placeDetail(MapPlace)
    case avatar
    case avatarEditor
    case passportIntro(avatar: Avatar, username: String?)
    case notificationPermission
    case myPhotos
    case mySuggestions
    case photoPrivacy
}

enum Sheet: Identifiable, Hashable {
    case itineraryDetail(slug: String)
    case suggestPlace

    var id: Self { self }
}
