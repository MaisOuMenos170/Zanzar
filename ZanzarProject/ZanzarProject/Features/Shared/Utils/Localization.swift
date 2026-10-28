import Foundation

/// Localization helper that works in all contexts (SwiftUI, Models, Services, etc.)
enum L10n {
    /// Bundle containing the localized strings (the app target).
    /// Uses a private class marker to resolve the correct bundle in both app and test contexts.
    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleLocator.self)
        #endif
    }()

    /// Private class used only to locate the app bundle.
    private final class BundleLocator {}

    /// Returns the localized string for the given key.
    /// Falls back to the key itself if localization fails.
    static func string(_ key: String, tableName: String? = nil, bundle: Bundle = bundle, comment: String = "") -> String {
        NSLocalizedString(key, tableName: tableName, bundle: bundle, comment: comment)
    }

    /// Returns the localized string with format arguments.
    static func string(_ key: String, _ arguments: CVarArg..., tableName: String? = nil, bundle: Bundle = bundle, comment: String = "") -> String {
        String(format: string(key, tableName: tableName, bundle: bundle, comment: comment), locale: Locale.current, arguments: arguments)
    }
}