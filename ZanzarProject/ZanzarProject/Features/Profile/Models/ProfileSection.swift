import SwiftUI

/// The two halves of the profile screen, picked with the segmented control under the avatar.
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
