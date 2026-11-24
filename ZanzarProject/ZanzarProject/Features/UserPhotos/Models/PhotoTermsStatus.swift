import Foundation

nonisolated struct PhotoTermsStatus: Equatable, Sendable {
    let hasAcceptedCurrentTerms: Bool
    /// `nil` until the user declared a birth date.
    let isAdult: Bool?

    var canUpload: Bool {
        hasAcceptedCurrentTerms && isAdult == true
    }
}
