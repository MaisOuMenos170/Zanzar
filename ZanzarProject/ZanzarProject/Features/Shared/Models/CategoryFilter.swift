import SwiftUI

enum CategoryFilter: String, CaseIterable, Identifiable {
    case all
    case parks
    case center
    case eat
    case museums
    case onFoot

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "categoryFilter.all"
        case .parks: "categoryFilter.parks"
        case .center: "categoryFilter.center"
        case .eat: "categoryFilter.eat"
        case .museums: "categoryFilter.museums"
        case .onFoot: "categoryFilter.onFoot"
        }
    }

    /// Whether an item of `category` stays in the list. An item with no known category only shows under "All".
    func includes(_ category: ZanzarPlaceCategory?) -> Bool {
        guard self != .all else { return true }
        guard let category else { return false }
        return categories.contains(category)
    }

    private var categories: Set<ZanzarPlaceCategory> {
        switch self {
        case .all: Set(ZanzarPlaceCategory.filterOptions)
        case .parks: [.park]
        case .center: [.center, .tourist, .historic]
        case .eat: [.restaurant, .cafe, .bar]
        case .museums: [.museum]
        case .onFoot: [.curiosity, .party]
        }
    }
}
