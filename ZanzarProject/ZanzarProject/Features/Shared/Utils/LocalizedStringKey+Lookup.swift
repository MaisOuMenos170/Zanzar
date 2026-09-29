import Foundation

extension String {
    /// Resolves a `Localizable.xcstrings` key at runtime (for keys stored in models).
    var localizedString: String {
        String(localized: String.LocalizationValue(self))
    }
}
