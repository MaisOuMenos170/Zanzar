import Foundation

/// Every way sending a photo can fail, in the terms the screen explains to the user.
nonisolated enum PhotoUploadError: Error, Equatable, Sendable {
    case duplicate
    case termsRequired
    case tooLarge
    case unsupportedFormat
    case unreadable
    case noCheckIn
    case unavailable
    case offline
    case rateLimited
    case sensitiveContent
    case generic

    /// The backend's refusal codes (`AppError.code`) and what each one means here.
    private static let byCode: [String: PhotoUploadError] = [
        "duplicate_photo": .duplicate,
        "terms_required": .termsRequired,
        "age_declaration_required": .termsRequired,
        "terms_outdated": .termsRequired,
        "image_too_large": .tooLarge,
        "unsupported_format": .unsupportedFormat,
        "invalid_check_in": .noCheckIn,
        "unreadable_image": .unreadable,
        "image_too_small": .unreadable,
        "photo_uploads_disabled": .unavailable,
        "storage_unavailable": .unavailable
    ]

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost
    ]

    init(_ error: Error) {
        if let known = error as? PhotoUploadError {
            self = known
        } else if let urlError = error as? URLError, Self.offlineCodes.contains(urlError.code) {
            self = .offline
        } else {
            switch error as? APIError {
            case .rejected(_, let code, _):
                self = Self.byCode[code] ?? .generic
            case .httpStatus(409, _):
                self = .duplicate
            case .httpStatus(413, _):
                self = .tooLarge
            case .rateLimited:
                self = .rateLimited
            default:
                self = .generic
            }
        }
    }

    var messageKey: String {
        switch self {
        case .duplicate: "userPhotos.uploadError.duplicate"
        case .termsRequired: "userPhotos.uploadError.termsRequired"
        case .tooLarge: "userPhotos.uploadError.tooLarge"
        case .unsupportedFormat: "userPhotos.uploadError.unsupportedFormat"
        case .unreadable: "userPhotos.uploadError.unreadable"
        case .noCheckIn: "userPhotos.uploadError.noCheckIn"
        case .unavailable: "userPhotos.uploadError.unavailable"
        case .offline: "userPhotos.uploadError.offline"
        case .rateLimited: "userPhotos.uploadError.rateLimited"
        case .sensitiveContent: "userPhotos.uploadError.sensitiveContent"
        case .generic: "userPhotos.uploadError.generic"
        }
    }

    /// Worth offering "Try again" with the same photo.
    var isRetryable: Bool {
        [.offline, .unavailable, .rateLimited, .generic].contains(self)
    }
}
