import Foundation

enum AvatarEditorTab: CaseIterable, Identifiable, Sendable {
    case skin
    case eyes
    case eyebrow
    case eyelash
    case hair

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .skin: "avatarEditor.title.skin"
        case .eyes: "avatarEditor.title.eyes"
        case .eyebrow: "avatarEditor.title.eyebrow"
        case .eyelash: "avatarEditor.title.eyelash"
        case .hair: "avatarEditor.title.hair"
        }
    }

    var iconName: String {
        switch self {
        case .skin: "AvatarTabs/skin"
        case .eyes: "AvatarTabs/eyes"
        case .eyebrow: "AvatarTabs/eyebrow"
        case .eyelash: "AvatarTabs/eyelash"
        case .hair: "AvatarTabs/hair"
        }
    }

    var optionCount: Int {
        switch self {
        case .skin: AvatarCatalog.skinCount
        case .eyes: AvatarCatalog.eyeColors.count
        case .eyebrow: AvatarCatalog.eyebrowColors.count
        case .eyelash: AvatarCatalog.eyelashColors.count
        case .hair: AvatarCatalog.hairCount
        }
    }

    var allowsNone: Bool {
        self == .eyelash || self == .hair
    }

    var gridColumnCount: Int {
        switch self {
        case .skin, .hair: 3
        case .eyes, .eyebrow, .eyelash: 4
        }
    }
}
