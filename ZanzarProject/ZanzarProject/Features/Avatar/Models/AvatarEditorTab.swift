import Foundation

/// A category of the avatar editor, in the order of the tab bar.
enum AvatarEditorTab: CaseIterable, Identifiable, Sendable {
    case skin
    case eyes
    case eyebrow
    case eyelash
    case hair

    var id: Self { self }

    /// Localization key of the screen title.
    var titleKey: String {
        switch self {
        case .skin: "avatarEditor.title.skin"
        case .eyes: "avatarEditor.title.eyes"
        case .eyebrow: "avatarEditor.title.eyebrow"
        case .eyelash: "avatarEditor.title.eyelash"
        case .hair: "avatarEditor.title.hair"
        }
    }

    /// Image in `Resources/Assets.xcassets/AvatarTabs`.
    var iconName: String {
        switch self {
        case .skin: "AvatarTabs/skin"
        case .eyes: "AvatarTabs/eyes"
        case .eyebrow: "AvatarTabs/eyebrow"
        case .eyelash: "AvatarTabs/eyelash"
        case .hair: "AvatarTabs/hair"
        }
    }

    /// Number of image options, not counting "none".
    var optionCount: Int {
        switch self {
        case .skin: AvatarCatalog.skinCount
        case .eyes: AvatarCatalog.eyeColors.count
        case .eyebrow: AvatarCatalog.eyebrowColors.count
        case .eyelash: AvatarCatalog.eyelashColors.count
        case .hair: AvatarCatalog.hairCount
        }
    }

    /// Eyelashes and hair can be turned off.
    var allowsNone: Bool {
        self == .eyelash || self == .hair
    }

    /// Columns of the option grid: swatches are small and fit four per row, face and hair pictures three.
    var gridColumnCount: Int {
        switch self {
        case .skin, .hair: 3
        case .eyes, .eyebrow, .eyelash: 4
        }
    }
}
