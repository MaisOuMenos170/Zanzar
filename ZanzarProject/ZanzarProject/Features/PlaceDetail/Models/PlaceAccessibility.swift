import Foundation

/// The accessibility resources a source confirms for a place. A place without it is "not checked yet", never
/// "not accessible". The values match `PLACE_ACCESSIBILITY_FEATURES` in the backend.
nonisolated struct PlaceAccessibility: Hashable, Sendable {
    let features: [PlaceAccessibilityFeature]
    let sourceLabel: String
    let sourceURL: URL
    let checkedAt: Date
}

nonisolated enum PlaceAccessibilityFeature: String, CaseIterable, Sendable {
    case elevator
    case ramp
    case accessibleRestroom = "accessible_restroom"
    case accessiblePaths = "accessible_paths"
    case accessibleParking = "accessible_parking"
    case wheelchairLoan = "wheelchair_loan"
    case tactileFloor = "tactile_floor"
    case braille
    case tactileMiniatures = "tactile_miniatures"
    case audioDescription = "audio_description"
    case inclusivePlayground = "inclusive_playground"
    case sensoryRoom = "sensory_room"
    case guideDogs = "guide_dogs"

    var symbolName: String {
        switch self {
        case .elevator: "arrow.up.arrow.down.square"
        case .ramp: "figure.roll"
        case .accessibleRestroom: "toilet"
        case .accessiblePaths: "road.lanes"
        case .accessibleParking: "parkingsign.circle"
        case .wheelchairLoan: "wheelchair"
        case .tactileFloor: "square.grid.3x3"
        case .braille: "hand.point.up.braille"
        case .tactileMiniatures: "cube.transparent"
        case .audioDescription: "ear.badge.waveform"
        case .inclusivePlayground: "figure.and.child.holdinghands"
        case .sensoryRoom: "speaker.slash"
        case .guideDogs: "dog"
        }
    }

    var titleKey: String {
        switch self {
        case .elevator: "placeDetail.accessibility.feature.elevator"
        case .ramp: "placeDetail.accessibility.feature.ramp"
        case .accessibleRestroom: "placeDetail.accessibility.feature.accessibleRestroom"
        case .accessiblePaths: "placeDetail.accessibility.feature.accessiblePaths"
        case .accessibleParking: "placeDetail.accessibility.feature.accessibleParking"
        case .wheelchairLoan: "placeDetail.accessibility.feature.wheelchairLoan"
        case .tactileFloor: "placeDetail.accessibility.feature.tactileFloor"
        case .braille: "placeDetail.accessibility.feature.braille"
        case .tactileMiniatures: "placeDetail.accessibility.feature.tactileMiniatures"
        case .audioDescription: "placeDetail.accessibility.feature.audioDescription"
        case .inclusivePlayground: "placeDetail.accessibility.feature.inclusivePlayground"
        case .sensoryRoom: "placeDetail.accessibility.feature.sensoryRoom"
        case .guideDogs: "placeDetail.accessibility.feature.guideDogs"
        }
    }
}
