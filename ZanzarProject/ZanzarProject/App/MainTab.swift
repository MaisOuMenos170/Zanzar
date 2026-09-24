import Foundation

enum MainTab: CaseIterable, Hashable {
    case discover
    case checkIn
    case profile

    var titleKey: String {
        switch self {
        case .discover:
            "mainTab.discoverTab.title"
        case .checkIn:
            "mainTab.checkInTab.title"
        case .profile:
            "mainTab.profileTab.title"
        }
    }

    var systemImage: String {
        switch self {
        case .discover:
            "map"
        case .checkIn:
            "mappin"
        case .profile:
            "person"
        }
    }
}
