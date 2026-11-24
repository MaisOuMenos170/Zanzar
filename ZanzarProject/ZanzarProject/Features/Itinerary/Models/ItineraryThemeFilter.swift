import SwiftUI

enum ItineraryThemeFilter: String, CaseIterable, Identifiable {
    case all
    case parks
    case center
    case food
    case museums
    case walking

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "categoryFilter.all"
        case .parks: "categoryFilter.parks"
        case .center: "categoryFilter.center"
        case .food: "categoryFilter.eat"
        case .museums: "categoryFilter.museums"
        case .walking: "categoryFilter.onFoot"
        }
    }

    func includes(_ itinerary: Itinerary) -> Bool {
        guard let theme else { return true }
        return itinerary.themes.contains(theme)
    }

    private var theme: ItineraryTheme? {
        switch self {
        case .all: nil
        case .parks: .parks
        case .center: .center
        case .food: .food
        case .museums: .museums
        case .walking: .walking
        }
    }
}
