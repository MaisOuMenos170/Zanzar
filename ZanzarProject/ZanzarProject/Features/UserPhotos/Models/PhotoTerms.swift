import Foundation

/// The photo terms the app shows. Bump `version` with any change to the text: the backend then asks everyone
/// to accept again (it must match the backend's `USER_PHOTO_TERMS_VERSION`).
nonisolated enum PhotoTerms {
    static let version = "2026-11-03"
    static let minimumAge = 18
}
