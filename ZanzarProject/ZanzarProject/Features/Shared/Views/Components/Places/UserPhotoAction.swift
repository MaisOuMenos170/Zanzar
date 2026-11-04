import SwiftUI

/// What someone can do with another person's photo on the place screen.
enum UserPhotoAction {
    case report
    case blockAuthor
}

/// Set by the place screen; the photo overlay calls it from its menu.
struct UserPhotoActionHandler: Equatable {
    let perform: (UserPhotoAttribution, UserPhotoAction) -> Void

    func callAsFunction(_ attribution: UserPhotoAttribution, _ action: UserPhotoAction) {
        perform(attribution, action)
    }

    // The place screen installs one handler for its lifetime; comparing closures would only cause redraws.
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

extension EnvironmentValues {
    /// `nil` hides the photo's report/block menu.
    @Entry var userPhotoActionHandler: UserPhotoActionHandler?
}
