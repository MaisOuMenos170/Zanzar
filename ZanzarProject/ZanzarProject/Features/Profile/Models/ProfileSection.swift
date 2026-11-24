import SwiftUI

enum ProfileSection: CaseIterable, Identifiable {
    case passport
    case settings

    var id: Self { self }

    var titleKey: LocalizedStringKey {
        switch self {
        case .passport: "profile.section.passport"
        case .settings: "profile.section.settings"
        }
    }
}
