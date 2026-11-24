import Foundation

/// Body of `POST /user/{id}/photo-terms`. The birth date is only used by the server to compute the age.
nonisolated struct AcceptPhotoTermsRequest: Encodable, Sendable {
    let version: String
    /// `YYYY-MM-DD`.
    let birthDate: String
}
