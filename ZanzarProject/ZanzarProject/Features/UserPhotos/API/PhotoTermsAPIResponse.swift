import Foundation

/// Body of `GET`/`POST /user/{id}/photo-terms`.
nonisolated struct PhotoTermsAPIResponse: Decodable, Sendable {
    let currentVersion: String
    let acceptedVersion: String?
    let isAdult: Bool?

    var status: PhotoTermsStatus {
        let acceptedCurrent = acceptedVersion == PhotoTerms.version && currentVersion == PhotoTerms.version
        return PhotoTermsStatus(hasAcceptedCurrentTerms: acceptedCurrent, isAdult: isAdult)
    }
}
