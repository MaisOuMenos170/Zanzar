import SwiftUI

enum MainTab: CaseIterable, Hashable {
    case discover
    case checkIn
    case profile
    /// Not a screen: the separate trailing tab (`role: .search`) that opens "Sugerir um lugar".
    /// `MainTabView` intercepts its selection, so it is never the selected tab.
    case suggest

    /// The tabs that show a screen, in the order of the tab bar.
    static let screenTabs: [MainTab] = [.discover, .checkIn, .profile]

    var titleKey: LocalizedStringKey {
        switch self {
        case .discover:
            "mainTab.discoverTab.title"
        case .checkIn:
            "mainTab.checkInTab.title"
        case .profile:
            "mainTab.profileTab.title"
        case .suggest:
            "placeSuggestion.toolbarButton.label"
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
        case .suggest:
            "plus.bubble"
        }
    }
}
