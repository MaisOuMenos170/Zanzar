import Foundation

enum Route: Hashable {
    case signUp
    case login
    case forgotPassword
    case resetCode(email: String)
    case codeVerified(resetToken: String)
    case newPassword(resetToken: String)
    case passwordResetSuccess
    /// `zoomsFromPin` is true when the push starts from a map pin, so the detail opens as a zoom out of it.
    case placeDetail(MapPlace, zoomsFromPin: Bool = false)
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
