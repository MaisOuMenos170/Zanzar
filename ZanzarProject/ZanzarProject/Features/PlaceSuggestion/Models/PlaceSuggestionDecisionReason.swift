import Foundation

/// Why a suggestion was refused or accepted by hand, from the backend's code, said in plain language.
/// Codes that only describe why it is being held (new account, possible duplicate...) are not shown to the user.
nonisolated enum PlaceSuggestionDecisionReason: Hashable, Sendable {
    case duplicate
    case outsideArea
    case typeNotAccepted
    case notARealPlace
    case inappropriate
    case acceptedManual
    case other(String)

    private static let byCode: [String: PlaceSuggestionDecisionReason] = [
        "duplicate": .duplicate,
        "outside_area": .outsideArea,
        "type_not_accepted": .typeNotAccepted,
        "not_a_real_place": .notARealPlace,
        "inappropriate": .inappropriate,
        "accepted_manual": .acceptedManual
    ]

    init(code: String) {
        self = Self.byCode[code] ?? .other(code)
    }

    /// The `placeSuggestion.decisionReason.*` key that explains it.
    var messageKey: String {
        switch self {
        case .duplicate: "placeSuggestion.decisionReason.duplicate"
        case .outsideArea: "placeSuggestion.decisionReason.outsideArea"
        case .typeNotAccepted: "placeSuggestion.decisionReason.typeNotAccepted"
        case .notARealPlace: "placeSuggestion.decisionReason.notARealPlace"
        case .inappropriate: "placeSuggestion.decisionReason.inappropriate"
        case .acceptedManual: "placeSuggestion.decisionReason.acceptedManual"
        case .other: "placeSuggestion.decisionReason.other"
        }
    }
}
