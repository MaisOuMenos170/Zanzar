import Foundation

/// Why a photo was held or refused, from the backend's code, said in plain language.
nonisolated enum UserPhotoDecisionReason: Hashable, Sendable {
    case nudity
    case violence
    case minors
    case faceProminent
    case personalData
    case offensiveText
    case watermark
    case notThePlace
    case lowQuality
    case possibleDuplicate
    case reported
    case other(String)

    private static let byCode: [String: UserPhotoDecisionReason] = [
        "nudity": .nudity,
        "violence": .violence,
        "minors": .minors,
        "face_prominent": .faceProminent,
        "personal_data": .personalData,
        "offensive_text": .offensiveText,
        "watermark": .watermark,
        "copyright": .watermark,
        "not_the_place": .notThePlace,
        "low_quality": .lowQuality,
        "possible_duplicate": .possibleDuplicate,
        "reported": .reported
    ]

    init(code: String) {
        self = Self.byCode[code] ?? .other(code)
    }

    /// The `userPhotos.decisionReason.*` key that explains it.
    var messageKey: String {
        switch self {
        case .nudity: "userPhotos.decisionReason.nudity"
        case .violence: "userPhotos.decisionReason.violence"
        case .minors: "userPhotos.decisionReason.minors"
        case .faceProminent: "userPhotos.decisionReason.faceProminent"
        case .personalData: "userPhotos.decisionReason.personalData"
        case .offensiveText: "userPhotos.decisionReason.offensiveText"
        case .watermark: "userPhotos.decisionReason.watermark"
        case .notThePlace: "userPhotos.decisionReason.notThePlace"
        case .lowQuality: "userPhotos.decisionReason.lowQuality"
        case .possibleDuplicate: "userPhotos.decisionReason.possibleDuplicate"
        case .reported: "userPhotos.decisionReason.reported"
        case .other: "userPhotos.decisionReason.other"
        }
    }
}
