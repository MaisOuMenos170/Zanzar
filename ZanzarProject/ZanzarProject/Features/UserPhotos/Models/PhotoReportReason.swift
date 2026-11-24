import Foundation

/// The reasons offered when reporting a photo; raw values are the backend's codes.
nonisolated enum PhotoReportReason: String, CaseIterable, Identifiable, Sendable {
    case inappropriate
    case notThePlace = "not_the_place"
    case peopleOrPrivacy = "people_or_privacy"
    case copyright
    case spam
    case other

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .inappropriate: "userPhotos.reportReason.inappropriate"
        case .notThePlace: "userPhotos.reportReason.notThePlace"
        case .peopleOrPrivacy: "userPhotos.reportReason.peopleOrPrivacy"
        case .copyright: "userPhotos.reportReason.copyright"
        case .spam: "userPhotos.reportReason.spam"
        case .other: "userPhotos.reportReason.other"
        }
    }
}
